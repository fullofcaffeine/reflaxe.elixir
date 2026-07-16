#include <erl_nif.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

typedef struct {
    uint64_t id;
    int64_t value;
    size_t roots;
    uint64_t *strong;
    size_t strong_count;
    uint64_t *weak;
    size_t weak_count;
    int marked;
} Object;

typedef struct {
    ErlNifMutex *lock;
    Object **slots;
    size_t slot_capacity;
    size_t live_objects;
    uint64_t next_id;
    uint64_t node_token;
    uint64_t lease_destructors;
    uint64_t collections;
    size_t lifetime_refs;
} Heap;

typedef struct {
    Heap *heap;
    uint64_t object_id;
} NativeLease;

typedef struct {
    ErlNifPid owner;
    uint64_t object_id;
} HybridLease;

typedef struct {
    ERL_NIF_TERM *items;
    size_t count;
    size_t capacity;
} TermStack;

typedef struct {
    uint64_t *items;
    size_t count;
    size_t capacity;
} IdVector;

typedef enum {
    SCAN_OK = 0,
    SCAN_OUT_OF_MEMORY,
    SCAN_WRONG_HEAP,
    SCAN_FOREIGN_CARRIER,
    SCAN_OPAQUE_CLOSURE
} ScanResult;

static ErlNifResourceType *native_lease_type = NULL;
static ErlNifResourceType *hybrid_lease_type = NULL;

static ERL_NIF_TERM atom_ok;
static ERL_NIF_TERM atom_error;
static ERL_NIF_TERM atom_true;
static ERL_NIF_TERM atom_false;
static ERL_NIF_TERM atom_not_found;
static ERL_NIF_TERM atom_wrong_node;
static ERL_NIF_TERM atom_wrong_node_or_stale;
static ERL_NIF_TERM atom_wrong_heap;
static ERL_NIF_TERM atom_foreign_carrier;
static ERL_NIF_TERM atom_opaque_closure;
static ERL_NIF_TERM atom_out_of_memory;
static ERL_NIF_TERM atom_roots_alive;
static ERL_NIF_TERM atom_hybrid_lease_down;
static ERL_NIF_TERM atom_live_objects;
static ERL_NIF_TERM atom_external_roots;
static ERL_NIF_TERM atom_lease_destructors;
static ERL_NIF_TERM atom_collections;
static ERL_NIF_TERM atom_node_token;
static ERL_NIF_TERM atom_id;
static ERL_NIF_TERM atom_value;
static ERL_NIF_TERM atom_roots;
static ERL_NIF_TERM atom_strong_edges;
static ERL_NIF_TERM atom_weak_edges;

static void object_destroy(Object *object) {
    if (object == NULL) {
        return;
    }
    enif_free(object->strong);
    enif_free(object->weak);
    enif_free(object);
}

static void heap_destroy(Heap *heap) {
    size_t index;
    if (heap == NULL) {
        return;
    }
    for (index = 0; index < heap->slot_capacity; index++) {
        object_destroy(heap->slots[index]);
    }
    enif_free(heap->slots);
    enif_mutex_destroy(heap->lock);
    enif_free(heap);
}

static Heap *heap_create(void) {
    Heap *heap = enif_alloc(sizeof(Heap));
    if (heap == NULL) {
        return NULL;
    }
    memset(heap, 0, sizeof(Heap));
    heap->lock = enif_mutex_create("managed_reference_spike_heap");
    if (heap->lock == NULL) {
        enif_free(heap);
        return NULL;
    }
    heap->next_id = 1;
    heap->lifetime_refs = 1;
    heap->node_token =
        ((uint64_t)(uintptr_t)heap) ^
        ((uint64_t)enif_monotonic_time(ERL_NIF_USEC) << 1) ^
        ((uint64_t)getpid() << 33);
    if (heap->node_token == 0) {
        heap->node_token = 1;
    }
    return heap;
}

static void heap_retain(Heap *heap) {
    enif_mutex_lock(heap->lock);
    heap->lifetime_refs++;
    enif_mutex_unlock(heap->lock);
}

static void heap_release(Heap *heap) {
    int destroy = 0;
    enif_mutex_lock(heap->lock);
    if (heap->lifetime_refs > 0) {
        heap->lifetime_refs--;
    }
    destroy = heap->lifetime_refs == 0;
    enif_mutex_unlock(heap->lock);
    if (destroy) {
        heap_destroy(heap);
    }
}

static int heap_ensure_capacity(Heap *heap, uint64_t id) {
    size_t old_capacity;
    size_t new_capacity;
    Object **resized;

    if (id < heap->slot_capacity) {
        return 1;
    }
    old_capacity = heap->slot_capacity;
    new_capacity = old_capacity == 0 ? 16 : old_capacity;
    while (id >= new_capacity) {
        if (new_capacity > SIZE_MAX / 2) {
            return 0;
        }
        new_capacity *= 2;
    }
    resized = enif_realloc(heap->slots, new_capacity * sizeof(Object *));
    if (resized == NULL) {
        return 0;
    }
    memset(resized + old_capacity, 0, (new_capacity - old_capacity) * sizeof(Object *));
    heap->slots = resized;
    heap->slot_capacity = new_capacity;
    return 1;
}

static Object *heap_get_object(Heap *heap, uint64_t id) {
    if (id == 0 || id >= heap->slot_capacity) {
        return NULL;
    }
    return heap->slots[id];
}

static Object *heap_allocate_object(Heap *heap, int64_t value) {
    uint64_t id = heap->next_id++;
    Object *object;
    if (!heap_ensure_capacity(heap, id)) {
        return NULL;
    }
    object = enif_alloc(sizeof(Object));
    if (object == NULL) {
        return NULL;
    }
    memset(object, 0, sizeof(Object));
    object->id = id;
    object->value = value;
    heap->slots[id] = object;
    heap->live_objects++;
    return object;
}

static ERL_NIF_TERM make_error(ErlNifEnv *env, ERL_NIF_TERM reason) {
    return enif_make_tuple2(env, atom_error, reason);
}

static int term_stack_push(TermStack *stack, ERL_NIF_TERM term) {
    ERL_NIF_TERM *resized;
    size_t capacity;
    if (stack->count == stack->capacity) {
        capacity = stack->capacity == 0 ? 16 : stack->capacity * 2;
        resized = enif_realloc(stack->items, capacity * sizeof(ERL_NIF_TERM));
        if (resized == NULL) {
            return 0;
        }
        stack->items = resized;
        stack->capacity = capacity;
    }
    stack->items[stack->count++] = term;
    return 1;
}

static int id_vector_add_unique(IdVector *vector, uint64_t id) {
    uint64_t *resized;
    size_t index;
    size_t capacity;
    for (index = 0; index < vector->count; index++) {
        if (vector->items[index] == id) {
            return 1;
        }
    }
    if (vector->count == vector->capacity) {
        capacity = vector->capacity == 0 ? 8 : vector->capacity * 2;
        resized = enif_realloc(vector->items, capacity * sizeof(uint64_t));
        if (resized == NULL) {
            return 0;
        }
        vector->items = resized;
        vector->capacity = capacity;
    }
    vector->items[vector->count++] = id;
    return 1;
}

static ScanResult scan_nested_leases(
    ErlNifEnv *env,
    Heap *expected_heap,
    ERL_NIF_TERM root,
    IdVector *ids
) {
    TermStack stack = {0};
    ScanResult result = SCAN_OK;
    if (!term_stack_push(&stack, root)) {
        return SCAN_OUT_OF_MEMORY;
    }

    while (stack.count > 0 && result == SCAN_OK) {
        ERL_NIF_TERM term = stack.items[--stack.count];
        NativeLease *native_lease = NULL;
        HybridLease *hybrid_lease = NULL;
        int arity;
        const ERL_NIF_TERM *elements;
        size_t map_size;

        if (enif_get_resource(env, term, native_lease_type, (void **)&native_lease)) {
            if (native_lease->heap != expected_heap) {
                result = SCAN_WRONG_HEAP;
            } else if (!id_vector_add_unique(ids, native_lease->object_id)) {
                result = SCAN_OUT_OF_MEMORY;
            }
            continue;
        }
        if (enif_get_resource(env, term, hybrid_lease_type, (void **)&hybrid_lease)) {
            (void)hybrid_lease;
            result = SCAN_FOREIGN_CARRIER;
            continue;
        }
        if (enif_is_fun(env, term)) {
            result = SCAN_OPAQUE_CLOSURE;
            continue;
        }
        if (enif_get_tuple(env, term, &arity, &elements)) {
            int index;
            for (index = 0; index < arity; index++) {
                if (!term_stack_push(&stack, elements[index])) {
                    result = SCAN_OUT_OF_MEMORY;
                    break;
                }
            }
            continue;
        }
        if (enif_get_map_size(env, term, &map_size)) {
            ErlNifMapIterator iterator;
            (void)map_size;
            if (enif_map_iterator_create(
                    env,
                    term,
                    &iterator,
                    ERL_NIF_MAP_ITERATOR_FIRST
                )) {
                ERL_NIF_TERM key;
                ERL_NIF_TERM value;
                while (enif_map_iterator_get_pair(env, &iterator, &key, &value)) {
                    if (!term_stack_push(&stack, key) || !term_stack_push(&stack, value)) {
                        result = SCAN_OUT_OF_MEMORY;
                        break;
                    }
                    if (!enif_map_iterator_next(env, &iterator)) {
                        break;
                    }
                }
                enif_map_iterator_destroy(env, &iterator);
            }
            continue;
        }
        if (enif_is_list(env, term)) {
            ERL_NIF_TERM current = term;
            ERL_NIF_TERM head;
            ERL_NIF_TERM tail;
            while (enif_get_list_cell(env, current, &head, &tail)) {
                if (!term_stack_push(&stack, head)) {
                    result = SCAN_OUT_OF_MEMORY;
                    break;
                }
                current = tail;
            }
            if (result == SCAN_OK && !enif_is_empty_list(env, current)) {
                if (!term_stack_push(&stack, current)) {
                    result = SCAN_OUT_OF_MEMORY;
                }
            }
        }
    }

    enif_free(stack.items);
    return result;
}

static ERL_NIF_TERM scan_error(ErlNifEnv *env, ScanResult result) {
    switch (result) {
        case SCAN_WRONG_HEAP:
            return make_error(env, atom_wrong_heap);
        case SCAN_FOREIGN_CARRIER:
            return make_error(env, atom_foreign_carrier);
        case SCAN_OPAQUE_CLOSURE:
            return make_error(env, atom_opaque_closure);
        case SCAN_OUT_OF_MEMORY:
        default:
            return make_error(env, atom_out_of_memory);
    }
}

static int get_native_lease(
    ErlNifEnv *env,
    ERL_NIF_TERM term,
    NativeLease **lease
) {
    return enif_get_resource(env, term, native_lease_type, (void **)lease);
}

static ERL_NIF_TERM make_native_lease_locked(
    ErlNifEnv *env,
    Heap *heap,
    Object *object
) {
    NativeLease *lease = enif_alloc_resource(native_lease_type, sizeof(NativeLease));
    ERL_NIF_TERM term;
    if (lease == NULL) {
        return make_error(env, atom_out_of_memory);
    }
    lease->heap = heap;
    lease->object_id = object->id;
    object->roots++;
    heap->lifetime_refs++;
    term = enif_make_resource(env, lease);
    enif_release_resource(lease);
    return term;
}

static void native_lease_dtor(ErlNifEnv *env, void *resource) {
    NativeLease *lease = resource;
    Heap *heap = lease->heap;
    Object *object;
    int destroy = 0;
    (void)env;

    enif_mutex_lock(heap->lock);
    object = heap_get_object(heap, lease->object_id);
    if (object != NULL && object->roots > 0) {
        object->roots--;
    }
    heap->lease_destructors++;
    if (heap->lifetime_refs > 0) {
        heap->lifetime_refs--;
    }
    destroy = heap->lifetime_refs == 0;
    enif_mutex_unlock(heap->lock);
    if (destroy) {
        heap_destroy(heap);
    }
}

static void hybrid_lease_dtor(ErlNifEnv *env, void *resource) {
    HybridLease *lease = resource;
    ERL_NIF_TERM message = enif_make_tuple2(
        env,
        atom_hybrid_lease_down,
        enif_make_uint64(env, lease->object_id)
    );
    (void)enif_send(env, &lease->owner, NULL, message);
}

static ERL_NIF_TERM new_object_nif(
    ErlNifEnv *env,
    int argc,
    const ERL_NIF_TERM argv[]
) {
    Heap *heap = enif_priv_data(env);
    ErlNifSInt64 value;
    Object *object;
    ERL_NIF_TERM result;
    (void)argc;
    if (!enif_get_int64(env, argv[0], &value)) {
        return enif_make_badarg(env);
    }
    enif_mutex_lock(heap->lock);
    object = heap_allocate_object(heap, value);
    if (object == NULL) {
        result = make_error(env, atom_out_of_memory);
    } else {
        result = make_native_lease_locked(env, heap, object);
    }
    enif_mutex_unlock(heap->lock);
    return result;
}

static ERL_NIF_TERM clone_nif(
    ErlNifEnv *env,
    int argc,
    const ERL_NIF_TERM argv[]
) {
    NativeLease *lease;
    Object *object;
    ERL_NIF_TERM result;
    (void)argc;
    if (!get_native_lease(env, argv[0], &lease)) {
        return make_error(env, atom_wrong_node_or_stale);
    }
    enif_mutex_lock(lease->heap->lock);
    object = heap_get_object(lease->heap, lease->object_id);
    result = object == NULL
        ? make_error(env, atom_not_found)
        : make_native_lease_locked(env, lease->heap, object);
    enif_mutex_unlock(lease->heap->lock);
    return result;
}

static ERL_NIF_TERM same_nif(
    ErlNifEnv *env,
    int argc,
    const ERL_NIF_TERM argv[]
) {
    NativeLease *left;
    NativeLease *right;
    (void)argc;
    if (!get_native_lease(env, argv[0], &left) ||
        !get_native_lease(env, argv[1], &right)) {
        return make_error(env, atom_wrong_node_or_stale);
    }
    return left->heap == right->heap && left->object_id == right->object_id
        ? atom_true
        : atom_false;
}

static ERL_NIF_TERM get_nif(
    ErlNifEnv *env,
    int argc,
    const ERL_NIF_TERM argv[]
) {
    NativeLease *lease;
    Object *object;
    ERL_NIF_TERM result;
    (void)argc;
    if (!get_native_lease(env, argv[0], &lease)) {
        return make_error(env, atom_wrong_node_or_stale);
    }
    enif_mutex_lock(lease->heap->lock);
    object = heap_get_object(lease->heap, lease->object_id);
    result = object == NULL
        ? make_error(env, atom_not_found)
        : enif_make_int64(env, object->value);
    enif_mutex_unlock(lease->heap->lock);
    return result;
}

static ERL_NIF_TERM put_nif(
    ErlNifEnv *env,
    int argc,
    const ERL_NIF_TERM argv[]
) {
    NativeLease *lease;
    Object *object;
    ErlNifSInt64 value;
    ERL_NIF_TERM result;
    (void)argc;
    if (!get_native_lease(env, argv[0], &lease)) {
        return make_error(env, atom_wrong_node_or_stale);
    }
    if (!enif_get_int64(env, argv[1], &value)) {
        return enif_make_badarg(env);
    }
    enif_mutex_lock(lease->heap->lock);
    object = heap_get_object(lease->heap, lease->object_id);
    if (object == NULL) {
        result = make_error(env, atom_not_found);
    } else {
        object->value = value;
        result = enif_make_int64(env, value);
    }
    enif_mutex_unlock(lease->heap->lock);
    return result;
}

static ERL_NIF_TERM increment_nif(
    ErlNifEnv *env,
    int argc,
    const ERL_NIF_TERM argv[]
) {
    NativeLease *lease;
    Object *object;
    ErlNifSInt64 delta;
    ERL_NIF_TERM result;
    (void)argc;
    if (!get_native_lease(env, argv[0], &lease)) {
        return make_error(env, atom_wrong_node_or_stale);
    }
    if (!enif_get_int64(env, argv[1], &delta)) {
        return enif_make_badarg(env);
    }
    enif_mutex_lock(lease->heap->lock);
    object = heap_get_object(lease->heap, lease->object_id);
    if (object == NULL) {
        result = make_error(env, atom_not_found);
    } else {
        object->value += delta;
        result = enif_make_int64(env, object->value);
    }
    enif_mutex_unlock(lease->heap->lock);
    return result;
}

static ERL_NIF_TERM set_nested_edges(
    ErlNifEnv *env,
    ERL_NIF_TERM owner_term,
    ERL_NIF_TERM nested,
    int weak
) {
    NativeLease *owner_lease;
    IdVector ids = {0};
    ScanResult scan;
    Object *owner;
    size_t index;
    ERL_NIF_TERM result;

    if (!get_native_lease(env, owner_term, &owner_lease)) {
        return make_error(env, atom_wrong_node_or_stale);
    }
    scan = scan_nested_leases(env, owner_lease->heap, nested, &ids);
    if (scan != SCAN_OK) {
        enif_free(ids.items);
        return scan_error(env, scan);
    }

    enif_mutex_lock(owner_lease->heap->lock);
    owner = heap_get_object(owner_lease->heap, owner_lease->object_id);
    if (owner == NULL) {
        result = make_error(env, atom_not_found);
    } else {
        for (index = 0; index < ids.count; index++) {
            if (heap_get_object(owner_lease->heap, ids.items[index]) == NULL) {
                break;
            }
        }
        if (index != ids.count) {
            result = make_error(env, atom_not_found);
        } else {
            if (weak) {
                enif_free(owner->weak);
                owner->weak = ids.items;
                owner->weak_count = ids.count;
            } else {
                enif_free(owner->strong);
                owner->strong = ids.items;
                owner->strong_count = ids.count;
            }
            ids.items = NULL;
            result = enif_make_tuple2(
                env,
                atom_ok,
                enif_make_uint64(env, ids.count)
            );
        }
    }
    enif_mutex_unlock(owner_lease->heap->lock);
    enif_free(ids.items);
    return result;
}

static ERL_NIF_TERM set_strong_nested_nif(
    ErlNifEnv *env,
    int argc,
    const ERL_NIF_TERM argv[]
) {
    (void)argc;
    return set_nested_edges(env, argv[0], argv[1], 0);
}

static ERL_NIF_TERM set_weak_nested_nif(
    ErlNifEnv *env,
    int argc,
    const ERL_NIF_TERM argv[]
) {
    (void)argc;
    return set_nested_edges(env, argv[0], argv[1], 1);
}

static ERL_NIF_TERM edge_ids_nif(
    ErlNifEnv *env,
    ERL_NIF_TERM owner_term,
    int weak
) {
    NativeLease *lease;
    Object *object;
    uint64_t *edges;
    size_t count;
    size_t index;
    ERL_NIF_TERM list = enif_make_list(env, 0);
    if (!get_native_lease(env, owner_term, &lease)) {
        return make_error(env, atom_wrong_node_or_stale);
    }
    enif_mutex_lock(lease->heap->lock);
    object = heap_get_object(lease->heap, lease->object_id);
    if (object == NULL) {
        enif_mutex_unlock(lease->heap->lock);
        return make_error(env, atom_not_found);
    }
    edges = weak ? object->weak : object->strong;
    count = weak ? object->weak_count : object->strong_count;
    for (index = count; index > 0; index--) {
        list = enif_make_list_cell(
            env,
            enif_make_uint64(env, edges[index - 1]),
            list
        );
    }
    enif_mutex_unlock(lease->heap->lock);
    return list;
}

static ERL_NIF_TERM strong_ids_nif(
    ErlNifEnv *env,
    int argc,
    const ERL_NIF_TERM argv[]
) {
    (void)argc;
    return edge_ids_nif(env, argv[0], 0);
}

static ERL_NIF_TERM weak_ids_nif(
    ErlNifEnv *env,
    int argc,
    const ERL_NIF_TERM argv[]
) {
    (void)argc;
    return edge_ids_nif(env, argv[0], 1);
}

static int id_in_edges(Object *object, uint64_t id) {
    size_t index;
    for (index = 0; index < object->strong_count; index++) {
        if (object->strong[index] == id) {
            return 1;
        }
    }
    for (index = 0; index < object->weak_count; index++) {
        if (object->weak[index] == id) {
            return 1;
        }
    }
    return 0;
}

static ERL_NIF_TERM lease_for_nif(
    ErlNifEnv *env,
    int argc,
    const ERL_NIF_TERM argv[]
) {
    NativeLease *owner_lease;
    ErlNifUInt64 id;
    Object *owner;
    Object *target;
    ERL_NIF_TERM result;
    (void)argc;
    if (!get_native_lease(env, argv[0], &owner_lease)) {
        return make_error(env, atom_wrong_node_or_stale);
    }
    if (!enif_get_uint64(env, argv[1], &id)) {
        return enif_make_badarg(env);
    }
    enif_mutex_lock(owner_lease->heap->lock);
    owner = heap_get_object(owner_lease->heap, owner_lease->object_id);
    target = heap_get_object(owner_lease->heap, id);
    if (owner == NULL || target == NULL || !id_in_edges(owner, id)) {
        result = make_error(env, atom_not_found);
    } else {
        result = make_native_lease_locked(env, owner_lease->heap, target);
    }
    enif_mutex_unlock(owner_lease->heap->lock);
    return result;
}

static ERL_NIF_TERM descriptor_nif(
    ErlNifEnv *env,
    int argc,
    const ERL_NIF_TERM argv[]
) {
    NativeLease *lease;
    (void)argc;
    if (!get_native_lease(env, argv[0], &lease)) {
        return make_error(env, atom_wrong_node_or_stale);
    }
    return enif_make_tuple2(
        env,
        enif_make_uint64(env, lease->heap->node_token),
        enif_make_uint64(env, lease->object_id)
    );
}

static ERL_NIF_TERM resolve_nif(
    ErlNifEnv *env,
    int argc,
    const ERL_NIF_TERM argv[]
) {
    Heap *heap = enif_priv_data(env);
    ErlNifUInt64 token;
    ErlNifUInt64 id;
    Object *object;
    ERL_NIF_TERM result;
    (void)argc;
    if (!enif_get_uint64(env, argv[0], &token) ||
        !enif_get_uint64(env, argv[1], &id)) {
        return enif_make_badarg(env);
    }
    if (token != heap->node_token) {
        return make_error(env, atom_wrong_node);
    }
    enif_mutex_lock(heap->lock);
    object = heap_get_object(heap, id);
    result = object == NULL
        ? make_error(env, atom_not_found)
        : make_native_lease_locked(env, heap, object);
    enif_mutex_unlock(heap->lock);
    return result;
}

static ERL_NIF_TERM object_info_nif(
    ErlNifEnv *env,
    int argc,
    const ERL_NIF_TERM argv[]
) {
    Heap *heap = enif_priv_data(env);
    ErlNifUInt64 id;
    Object *object;
    ERL_NIF_TERM map;
    ERL_NIF_TERM value;
    (void)argc;
    if (!enif_get_uint64(env, argv[0], &id)) {
        return enif_make_badarg(env);
    }
    enif_mutex_lock(heap->lock);
    object = heap_get_object(heap, id);
    if (object == NULL) {
        enif_mutex_unlock(heap->lock);
        return make_error(env, atom_not_found);
    }
    map = enif_make_new_map(env);
    value = enif_make_uint64(env, object->id);
    (void)enif_make_map_put(env, map, atom_id, value, &map);
    value = enif_make_int64(env, object->value);
    (void)enif_make_map_put(env, map, atom_value, value, &map);
    value = enif_make_uint64(env, object->roots);
    (void)enif_make_map_put(env, map, atom_roots, value, &map);
    value = enif_make_uint64(env, object->strong_count);
    (void)enif_make_map_put(env, map, atom_strong_edges, value, &map);
    value = enif_make_uint64(env, object->weak_count);
    (void)enif_make_map_put(env, map, atom_weak_edges, value, &map);
    enif_mutex_unlock(heap->lock);
    return enif_make_tuple2(env, atom_ok, map);
}

static ERL_NIF_TERM stats_nif(
    ErlNifEnv *env,
    int argc,
    const ERL_NIF_TERM argv[]
) {
    Heap *heap = enif_priv_data(env);
    ERL_NIF_TERM map;
    ERL_NIF_TERM value;
    size_t index;
    size_t roots = 0;
    (void)argc;
    (void)argv;
    enif_mutex_lock(heap->lock);
    for (index = 0; index < heap->slot_capacity; index++) {
        if (heap->slots[index] != NULL) {
            roots += heap->slots[index]->roots;
        }
    }
    map = enif_make_new_map(env);
    value = enif_make_uint64(env, heap->live_objects);
    (void)enif_make_map_put(env, map, atom_live_objects, value, &map);
    value = enif_make_uint64(env, roots);
    (void)enif_make_map_put(env, map, atom_external_roots, value, &map);
    value = enif_make_uint64(env, heap->lease_destructors);
    (void)enif_make_map_put(env, map, atom_lease_destructors, value, &map);
    value = enif_make_uint64(env, heap->collections);
    (void)enif_make_map_put(env, map, atom_collections, value, &map);
    value = enif_make_uint64(env, heap->node_token);
    (void)enif_make_map_put(env, map, atom_node_token, value, &map);
    enif_mutex_unlock(heap->lock);
    return map;
}

static void mark_object(Heap *heap, Object *object, uint64_t *stack, size_t *count) {
    if (object != NULL && !object->marked) {
        object->marked = 1;
        stack[(*count)++] = object->id;
    }
    (void)heap;
}

static ERL_NIF_TERM collect_nif(
    ErlNifEnv *env,
    int argc,
    const ERL_NIF_TERM argv[]
) {
    Heap *heap = enif_priv_data(env);
    uint64_t *stack;
    size_t stack_count = 0;
    size_t index;
    size_t collected = 0;
    (void)argc;
    (void)argv;

    enif_mutex_lock(heap->lock);
    stack = enif_alloc(
        (heap->slot_capacity == 0 ? 1 : heap->slot_capacity) * sizeof(uint64_t)
    );
    if (stack == NULL) {
        enif_mutex_unlock(heap->lock);
        return make_error(env, atom_out_of_memory);
    }

    for (index = 0; index < heap->slot_capacity; index++) {
        Object *object = heap->slots[index];
        if (object != NULL && object->roots > 0) {
            mark_object(heap, object, stack, &stack_count);
        }
    }
    while (stack_count > 0) {
        Object *object = heap_get_object(heap, stack[--stack_count]);
        size_t edge_index;
        if (object == NULL) {
            continue;
        }
        for (edge_index = 0; edge_index < object->strong_count; edge_index++) {
            mark_object(
                heap,
                heap_get_object(heap, object->strong[edge_index]),
                stack,
                &stack_count
            );
        }
    }

    for (index = 0; index < heap->slot_capacity; index++) {
        Object *object = heap->slots[index];
        if (object != NULL && !object->marked) {
            object_destroy(object);
            heap->slots[index] = NULL;
            heap->live_objects--;
            collected++;
        }
    }
    for (index = 0; index < heap->slot_capacity; index++) {
        Object *object = heap->slots[index];
        size_t read_index;
        size_t write_index = 0;
        if (object == NULL) {
            continue;
        }
        object->marked = 0;
        for (read_index = 0; read_index < object->weak_count; read_index++) {
            if (heap_get_object(heap, object->weak[read_index]) != NULL) {
                object->weak[write_index++] = object->weak[read_index];
            }
        }
        object->weak_count = write_index;
    }
    heap->collections++;
    enif_free(stack);
    enif_mutex_unlock(heap->lock);
    return enif_make_uint64(env, collected);
}

static ERL_NIF_TERM reset_nif(
    ErlNifEnv *env,
    int argc,
    const ERL_NIF_TERM argv[]
) {
    Heap *heap = enif_priv_data(env);
    size_t index;
    size_t roots = 0;
    size_t cleared;
    (void)argc;
    (void)argv;
    enif_mutex_lock(heap->lock);
    for (index = 0; index < heap->slot_capacity; index++) {
        if (heap->slots[index] != NULL) {
            roots += heap->slots[index]->roots;
        }
    }
    if (roots != 0) {
        enif_mutex_unlock(heap->lock);
        return make_error(env, atom_roots_alive);
    }
    cleared = heap->live_objects;
    for (index = 0; index < heap->slot_capacity; index++) {
        object_destroy(heap->slots[index]);
        heap->slots[index] = NULL;
    }
    heap->live_objects = 0;
    heap->next_id = 1;
    heap->lease_destructors = 0;
    heap->collections = 0;
    enif_mutex_unlock(heap->lock);
    return enif_make_uint64(env, cleared);
}

static ERL_NIF_TERM new_hybrid_lease_nif(
    ErlNifEnv *env,
    int argc,
    const ERL_NIF_TERM argv[]
) {
    ErlNifPid owner;
    ErlNifUInt64 id;
    HybridLease *lease;
    ERL_NIF_TERM term;
    (void)argc;
    if (!enif_get_local_pid(env, argv[0], &owner) ||
        !enif_get_uint64(env, argv[1], &id)) {
        return enif_make_badarg(env);
    }
    lease = enif_alloc_resource(hybrid_lease_type, sizeof(HybridLease));
    if (lease == NULL) {
        return make_error(env, atom_out_of_memory);
    }
    lease->owner = owner;
    lease->object_id = id;
    term = enif_make_resource(env, lease);
    enif_release_resource(lease);
    return term;
}

static ERL_NIF_TERM hybrid_id_nif(
    ErlNifEnv *env,
    int argc,
    const ERL_NIF_TERM argv[]
) {
    HybridLease *lease;
    (void)argc;
    if (!enif_get_resource(env, argv[0], hybrid_lease_type, (void **)&lease)) {
        return make_error(env, atom_wrong_node_or_stale);
    }
    return enif_make_tuple2(
        env,
        atom_ok,
        enif_make_uint64(env, lease->object_id)
    );
}

static ERL_NIF_TERM nif_info_nif(
    ErlNifEnv *env,
    int argc,
    const ERL_NIF_TERM argv[]
) {
    (void)argc;
    (void)argv;
    return enif_make_tuple3(
        env,
        enif_make_int(env, ERL_NIF_MAJOR_VERSION),
        enif_make_int(env, ERL_NIF_MINOR_VERSION),
        enif_make_uint(env, (unsigned int)sizeof(void *))
    );
}

static void initialize_atoms(ErlNifEnv *env) {
    atom_ok = enif_make_atom(env, "ok");
    atom_error = enif_make_atom(env, "error");
    atom_true = enif_make_atom(env, "true");
    atom_false = enif_make_atom(env, "false");
    atom_not_found = enif_make_atom(env, "not_found");
    atom_wrong_node = enif_make_atom(env, "wrong_node");
    atom_wrong_node_or_stale = enif_make_atom(env, "wrong_node_or_stale");
    atom_wrong_heap = enif_make_atom(env, "wrong_heap");
    atom_foreign_carrier = enif_make_atom(env, "foreign_carrier");
    atom_opaque_closure = enif_make_atom(env, "opaque_closure");
    atom_out_of_memory = enif_make_atom(env, "out_of_memory");
    atom_roots_alive = enif_make_atom(env, "roots_alive");
    atom_hybrid_lease_down = enif_make_atom(env, "hybrid_lease_down");
    atom_live_objects = enif_make_atom(env, "live_objects");
    atom_external_roots = enif_make_atom(env, "external_roots");
    atom_lease_destructors = enif_make_atom(env, "lease_destructors");
    atom_collections = enif_make_atom(env, "collections");
    atom_node_token = enif_make_atom(env, "node_token");
    atom_id = enif_make_atom(env, "id");
    atom_value = enif_make_atom(env, "value");
    atom_roots = enif_make_atom(env, "roots");
    atom_strong_edges = enif_make_atom(env, "strong_edges");
    atom_weak_edges = enif_make_atom(env, "weak_edges");
}

static int open_resource_types(ErlNifEnv *env) {
    ErlNifResourceFlags flags = ERL_NIF_RT_CREATE | ERL_NIF_RT_TAKEOVER;
    native_lease_type = enif_open_resource_type(
        env,
        NULL,
        "managed_reference_native_lease",
        native_lease_dtor,
        flags,
        NULL
    );
    hybrid_lease_type = enif_open_resource_type(
        env,
        NULL,
        "managed_reference_hybrid_lease",
        hybrid_lease_dtor,
        flags,
        NULL
    );
    return native_lease_type != NULL && hybrid_lease_type != NULL;
}

static int load(ErlNifEnv *env, void **priv_data, ERL_NIF_TERM load_info) {
    Heap *heap;
    (void)load_info;
    initialize_atoms(env);
    if (!open_resource_types(env)) {
        return 1;
    }
    heap = heap_create();
    if (heap == NULL) {
        return 1;
    }
    *priv_data = heap;
    return 0;
}

static int upgrade(
    ErlNifEnv *env,
    void **priv_data,
    void **old_priv_data,
    ERL_NIF_TERM load_info
) {
    Heap *heap;
    (void)load_info;
    if (old_priv_data == NULL || *old_priv_data == NULL) {
        return load(env, priv_data, load_info);
    }
    initialize_atoms(env);
    if (!open_resource_types(env)) {
        return 1;
    }
    heap = *old_priv_data;
    heap_retain(heap);
    *priv_data = heap;
    return 0;
}

static void unload(ErlNifEnv *env, void *priv_data) {
    (void)env;
    heap_release(priv_data);
}

static ErlNifFunc nif_functions[] = {
    {"new_object", 1, new_object_nif, 0},
    {"clone", 1, clone_nif, 0},
    {"same", 2, same_nif, 0},
    {"get", 1, get_nif, 0},
    {"put", 2, put_nif, 0},
    {"increment", 2, increment_nif, 0},
    {"set_strong_nested", 2, set_strong_nested_nif, 0},
    {"set_weak_nested", 2, set_weak_nested_nif, 0},
    {"strong_ids", 1, strong_ids_nif, 0},
    {"weak_ids", 1, weak_ids_nif, 0},
    {"lease_for", 2, lease_for_nif, 0},
    {"descriptor", 1, descriptor_nif, 0},
    {"resolve", 2, resolve_nif, 0},
    {"object_info", 1, object_info_nif, 0},
    {"stats", 0, stats_nif, 0},
    {"collect", 0, collect_nif, ERL_NIF_DIRTY_JOB_CPU_BOUND},
    {"reset", 0, reset_nif, 0},
    {"new_hybrid_lease", 2, new_hybrid_lease_nif, 0},
    {"hybrid_id", 1, hybrid_id_nif, 0},
    {"nif_info", 0, nif_info_nif, 0}
};

ERL_NIF_INIT(
    Elixir.ManagedReferenceSpike.Native,
    nif_functions,
    load,
    NULL,
    upgrade,
    unload
)

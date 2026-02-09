package phoenix_chat_hx.live;

import phoenix_chat_hx.presence.ChatPresence.PresenceMeta;

typedef ChatMessage = {
    var id: Int;
    var user_id: String;
    var user_name: String;
    var body: String;
    var at: Float;
    var row_class: String;
}

typedef OnlineUserView = {
    var user_id: String;
    var name: String;
    var online_at: Float;
    var is_me: Bool;
    var row_class: String;
}

typedef AppLiveAssigns = {
    room: String,
    current_user_id: String,
    current_user_name: String,
    message_input: String,
    messages: Array<ChatMessage>,
    next_message_id: Int,
    presence_initialized: Bool,
    online_users: Map<String, phoenix.Presence.PresenceEntry<PresenceMeta>>,
    online_user_views: Array<OnlineUserView>,
    online_user_count: Int,
    status: Null<String>,
}

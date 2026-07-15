import {PreferenceStudio} from "./preference-studio"
import type {PreferenceChangedPayload, PreferenceStudioInput} from "./preference-studio-contract"
import type {ComponentName} from "./registry.generated"

const onPreferenceChanged = (_payload: PreferenceChangedPayload): void => {}
const validInput: PreferenceStudioInput = {title: "Density", density: "focused"}
const validComponent: ComponentName = "PreferenceStudio"
const validView = <PreferenceStudio {...validInput} onPreferenceChanged={onPreferenceChanged} />

// @ts-expect-error unknown density values are outside the public contract
const invalidDensity: PreferenceStudioInput = {title: "Density", density: "loud"}
// @ts-expect-error arbitrary inputs cannot enter the inner component
const leakedBridge = <PreferenceStudio {...validInput} onPreferenceChanged={onPreferenceChanged} pushEvent={() => {}} />
// @ts-expect-error the static registry rejects ambient component names
const unknownComponent: ComponentName = "UnknownComponent"
// @ts-expect-error event payloads have one exact field
const invalidPayload: PreferenceChangedPayload = {density: "calm", extra: true}

void [validComponent, validView, invalidDensity, leakedBridge, unknownComponent, invalidPayload]

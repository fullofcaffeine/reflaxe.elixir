import {useEffect, useId, useState} from "react"
import type {PreferenceChangedPayload, PreferenceDensity, PreferenceStudioInput} from "./preference-studio-contract"

export interface PreferenceStudioProps extends PreferenceStudioInput {
  readonly onPreferenceChanged: (payload: PreferenceChangedPayload) => void
}

const options: ReadonlyArray<{
  density: PreferenceDensity
  label: string
  note: string
  rhythm: string
}> = [
  {density: "calm", label: "Calm", note: "Long focus windows, one shared table", rhythm: "01 / spacious"},
  {density: "focused", label: "Focused", note: "A measured cadence with room to reply", rhythm: "02 / balanced"},
  {density: "dense", label: "Dense", note: "More crossings for an active working week", rhythm: "03 / kinetic"},
]

const activeSignals: Record<PreferenceDensity, number> = {
  calm: 4,
  focused: 7,
  dense: 11,
}

export function PreferenceStudio({title, density, onPreferenceChanged}: PreferenceStudioProps) {
  const [draft, setDraft] = useState<PreferenceDensity>(density)
  const headingId = useId()
  const hasPendingChange = draft !== density

  useEffect(() => setDraft(density), [density])

  return (
    <section
      className="preference-studio"
      aria-labelledby={headingId}
      data-density={draft}
      data-testid="preference-studio"
    >
      <header className="preference-studio__header">
        <div>
          <p className="preference-studio__eyebrow">Working rhythm / local preview</p>
          <h3 id={headingId}>{title}</h3>
        </div>
        <span className="preference-studio__readout" aria-label={`Current density: ${density}`}>
          {density}
        </span>
      </header>

      <div className="preference-studio__map" data-testid="preference-map" aria-hidden="true">
        <span className="preference-studio__map-label">A week in the room</span>
        <div className="preference-studio__signals">
          {Array.from({length: 12}, (_, index) => (
            <i key={index} data-active={index < activeSignals[draft]} />
          ))}
        </div>
        <span className="preference-studio__map-count">{activeSignals[draft].toString().padStart(2, "0")} signals</span>
      </div>

      <div className="preference-studio__options" aria-label="Choose interface density">
        {options.map((option) => (
          <button
            key={option.density}
            type="button"
            className="preference-studio__option"
            aria-pressed={draft === option.density}
            onClick={() => setDraft(option.density)}
          >
            <span className="preference-studio__rhythm">{option.rhythm}</span>
            <strong>{option.label}</strong>
            <span>{option.note}</span>
          </button>
        ))}
      </div>

      <footer className="preference-studio__footer">
        <span aria-live="polite">{hasPendingChange ? `${draft} is ready to apply` : `${density} is active`}</span>
        <button
          type="button"
          className="preference-studio__apply"
          disabled={!hasPendingChange}
          onClick={() => onPreferenceChanged({density: draft})}
        >
          Apply {draft}
        </button>
      </footer>
    </section>
  )
}

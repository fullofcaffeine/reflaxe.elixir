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
  {density: "calm", label: "Calm", note: "More air and fewer interruptions", rhythm: "01 / spacious"},
  {density: "focused", label: "Focused", note: "A balanced working cadence", rhythm: "02 / balanced"},
  {density: "dense", label: "Dense", note: "Maximum signal per viewport", rhythm: "03 / compact"},
]

export function PreferenceStudio({title, density, onPreferenceChanged}: PreferenceStudioProps) {
  const [draft, setDraft] = useState<PreferenceDensity>(density)
  const headingId = useId()
  const hasPendingChange = draft !== density

  useEffect(() => setDraft(density), [density])

  return (
    <section className="preference-studio" aria-labelledby={headingId} data-testid="preference-studio">
      <header className="preference-studio__header">
        <div>
          <p className="preference-studio__eyebrow">Interface signal</p>
          <h3 id={headingId}>{title}</h3>
        </div>
        <span className="preference-studio__readout" aria-label={`Current density: ${density}`}>
          {density}
        </span>
      </header>

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
        <span aria-live="polite">{hasPendingChange ? `Ready to apply ${draft}` : `${density} is active`}</span>
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

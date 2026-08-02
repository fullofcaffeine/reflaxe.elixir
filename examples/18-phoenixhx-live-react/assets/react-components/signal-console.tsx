import {useState} from "react"

export interface SignalConsoleProps {
  readonly title: string
  readonly pulseCount: number
  readonly onPulse: (channel: (typeof channels)[number]) => void
}

const channels = ["ALPHA", "BETA", "GAMMA"] as const

/** Hand-owned React implementation behind the generated closed boundary. */
export function SignalConsole({title, pulseCount, onPulse}: SignalConsoleProps) {
  const [channel, setChannel] = useState<(typeof channels)[number]>("ALPHA")

  const nextChannel = () => {
    const current = channels.indexOf(channel)
    setChannel(channels[(current + 1) % channels.length])
  }

  return (
    <section className="signal-console" data-react-island="signal-console">
      <header className="signal-console__header">
        <div>
          <p className="signal-console__eyebrow">LiveReact island / online</p>
          <h2>{title}</h2>
        </div>
        <span className="signal-console__status" aria-label="Connection active">
          Active
        </span>
      </header>

      <div className="signal-console__readout" aria-live="polite">
        <span>Pulse count</span>
        <strong data-testid="pulse-count" data-signal-count={pulseCount}>
          {String(pulseCount).padStart(2, "0")}
        </strong>
      </div>

      <div className="signal-console__meter" aria-hidden="true">
        {Array.from({length: 8}, (_, index) => (
          <i key={index} className={index < Math.min(pulseCount, 8) ? "is-lit" : ""} />
        ))}
      </div>

      <div className="signal-console__controls">
        <button data-testid="transmit-pulse" type="button" onClick={() => onPulse(channel)}>
          Transmit pulse
        </button>
        <button data-testid="cycle-channel" className="signal-console__channel" type="button" onClick={nextChannel}>
          Channel <b>{channel}</b>
        </button>
      </div>

      <p className="signal-console__footnote">
        Channel selection lives in React. Phoenix owns the count after validating the typed event.
      </p>
    </section>
  )
}

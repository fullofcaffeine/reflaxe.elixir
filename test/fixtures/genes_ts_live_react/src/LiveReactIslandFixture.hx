package;

import genes.react.Element;
import genes.react.JSX.*;
import genes.ts.Imports;

enum abstract Density(String) to String {
	var Compact = "compact";
	var Comfortable = "comfortable";
}

typedef StatusPanelProps = {
	final title:String;
	final density:Density;
	final onAction:Density->Void;
}

/**
 * Haxe-authored React island shared by strict TSX and classic Genes ESM.
 *
 * The closed props and callback contract model the application-facing side of
 * a trusted LiveReact boundary. Stock LiveReact still owns mounting and the
 * native bridge; this component receives only semantic values and callbacks.
 */
@:expose
function StatusPanel(props:StatusPanelProps):Element {
	return <section data-react-island="status-panel" data-density={props.density}>
		<h2>{props.title}</h2>
		<button type="button" onClick={() -> props.onAction(props.density)}>Continue</button>
	</section>;
}

/** Closed static registry shape consumed by a stock LiveReact hook adapter. */
@:expose
final componentRegistry = {
	StatusPanel: StatusPanel
};

class LiveReactIslandFixture {
	static function main():Void {
		final renderToStaticMarkup:Element->String = Imports.namedImport("react-dom/server", "renderToStaticMarkup");
		final component:StatusPanelProps->Element = StatusPanel;
		final html = renderToStaticMarkup(component({
			title: "Typed from Haxe",
			density: Compact,
			onAction: function(_:Density):Void {}
		}));

		final expected = '<section data-react-island="status-panel" data-density="compact"><h2>Typed from Haxe</h2><button type="button">Continue</button></section>';
		if (html != expected)
			throw "unexpected LiveReact island HTML: " + html;

		final RegistryComponent = componentRegistry.StatusPanel;
		final registryHtml = renderToStaticMarkup(RegistryComponent({
			title: "From registry",
			density: Comfortable,
			onAction: function(_:Density):Void {}
		}));
		if (registryHtml.indexOf('data-density="comfortable"') == -1)
			throw "static registry lost the closed density contract: " + registryHtml;

		#if genes_test_invalid_props
		// genes-ts v1.37+ validates component props while Haxe types the inline HXX.
		// The negative build enables this branch and requires GTS-HXX-PROP-002.
		final invalid = <RegistryComponent title={123} density={Density.Compact} onAction={function(_:Density):Void {}} />;
		if (invalid == null)
			throw "unreachable";
		#end

		js.Syntax.code("console.log({0})", html);
	}
}

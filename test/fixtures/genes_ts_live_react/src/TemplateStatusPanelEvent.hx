package;

/** Template-origin events remain owned by the Phoenix HXX boundary. */
@:liveEventProtocol
enum TemplateStatusPanelEvent {
	@:templateEvent("status_panel_clicked")
	Clicked;
}

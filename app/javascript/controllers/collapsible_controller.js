import { Controller } from "@hotwired/stimulus"

// Manages show/hide behavior for collapsible sections.
export default class extends Controller {
    static targets = ["content", "toggle"]
    static values = { expanded: Boolean, showLabel: String, hideLabel: String }

    connect() {
        if (!this.hasExpandedValue) {
            this.expandedValue = true
        }
        this.update()
    }

    toggle(event) {
        event.preventDefault()
        this.expandedValue = !this.expandedValue
    }

    expandedValueChanged() {
        this.update()
    }

    update() {
        if (!this.hasContentTarget || !this.hasToggleTarget) return

        const isExpanded = this.expandedValue

        this.contentTarget.hidden = !isExpanded
        this.contentTarget.style.display = isExpanded ? "" : "none"
        this.toggleTarget.setAttribute("aria-expanded", String(isExpanded))
        this.toggleTarget.textContent = isExpanded ? this.hideLabel : this.showLabel
    }

    get showLabel() {
        return this.hasShowLabelValue ? this.showLabelValue : "Show"
    }

    get hideLabel() {
        return this.hasHideLabelValue ? this.hideLabelValue : "Hide"
    }
}

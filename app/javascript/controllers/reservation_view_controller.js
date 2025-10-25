import { Controller } from "@hotwired/stimulus"

// Toggles between calendar and list views for reservations.
export default class extends Controller {
    static targets = ["calendar", "list", "toggle"]
    static values = { mode: { type: String, default: "calendar" }, listLabel: String, calendarLabel: String }

    connect() {
        if (!this.hasModeValue) {
            this.modeValue = "calendar"
        }
        this.update()
    }

    toggle(event) {
        event.preventDefault()
        this.modeValue = this.modeValue === "calendar" ? "list" : "calendar"
    }

    modeValueChanged() {
        this.update()
    }

    update() {
        if (!this.hasCalendarTarget || !this.hasListTarget || !this.hasToggleTarget) return

        const showCalendar = this.modeValue === "calendar"
        this.calendarTarget.hidden = !showCalendar
        this.calendarTarget.style.display = showCalendar ? "" : "none"
        this.listTarget.hidden = showCalendar
        this.listTarget.style.display = showCalendar ? "none" : ""

        const buttonLabel = showCalendar ? this.listLabel : this.calendarLabel
        this.toggleTarget.textContent = buttonLabel
        this.toggleTarget.setAttribute("aria-pressed", String(!showCalendar))
    }

    get listLabel() {
        return this.hasListLabelValue ? this.listLabelValue : "List"
    }

    get calendarLabel() {
        return this.hasCalendarLabelValue ? this.calendarLabelValue : "Calendar"
    }
}

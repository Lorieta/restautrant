import { Controller } from "@hotwired/stimulus"

// Submits the surrounding form when a select changes (used for inline status updates)
export default class extends Controller {
    submit(event) {
        const select = event.target
        const form = select.closest('form')
        if (!form) return
        // Prefer requestSubmit for modern browsers to trigger proper form behavior
        if (typeof form.requestSubmit === 'function') {
            form.requestSubmit()
        } else {
            form.submit()
        }
    }
}

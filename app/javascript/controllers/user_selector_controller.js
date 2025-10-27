import { Controller } from "@hotwired/stimulus"

// Updates contact details when a user is selected in the reservation form.
export default class extends Controller {
    static targets = ["select", "name", "phone", "email", "wrapper"]

    connect() {
        // Parse users JSON from wrapper dataset if present
        try {
            if (this.hasWrapperTarget) {
                const raw = this.wrapperTarget.dataset.users
                this.users = raw ? JSON.parse(raw) : []
            } else {
                this.users = []
            }
        } catch (err) {
            console.error('user-selector: failed to parse users data', err)
            this.users = []
        }

        // If a select exists, attach change handler and set initial values
        if (this.hasSelectTarget) {
            this.selectTarget.addEventListener('change', this.onUserChange.bind(this))
            this.updateContactFromSelect()
        }
    }

    onUserChange(event) {
        this.updateContactFromSelect()
    }

    updateContactFromSelect() {
        const val = this.hasSelectTarget ? this.selectTarget.value : null
        let user = null

        if (val && this.users && this.users.length) {
            user = this.users.find(u => String(u.id) === String(val))
        }

        if (!user) {
            // Fall back to first user in list if available
            user = (this.users && this.users.length) ? this.users[0] : null
        }

        this._updateContact(user)
    }

    _updateContact(user) {
        const name = user && user.name ? user.name : ''
        const phone = user && user.phone ? user.phone : ''
        const email = user && user.email ? user.email : ''

        if (this.hasNameTarget) this.nameTarget.textContent = name
        if (this.hasPhoneTarget) this.phoneTarget.textContent = phone || 'N/A'
        if (this.hasEmailTarget) this.emailTarget.textContent = email
    }
}

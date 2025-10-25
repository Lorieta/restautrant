import { Controller } from "@hotwired/stimulus"

// Provides a reusable confirmation modal for CRUD operations.
export default class extends Controller {
    static targets = ["backdrop", "title", "message", "confirmButton", "cancelButton"]
    static values = {
        defaultTitle: { type: String, default: "Confirm Action" },
        defaultMessage: { type: String, default: "Are you sure you want to continue?" },
        defaultConfirmText: { type: String, default: "Confirm" },
        defaultCancelText: { type: String, default: "Cancel" }
    }

    connect() {
        this.confirmButtonBaseClass = this.confirmButtonTarget.className
        this.cancelButtonBaseClass = this.cancelButtonTarget.className
        this.handleKeydown = this.handleKeydown.bind(this)
        document.addEventListener("keydown", this.handleKeydown)
    }

    disconnect() {
        document.removeEventListener("keydown", this.handleKeydown)
    }

    ask(event) {
        const trigger = event.currentTarget

        if (trigger.dataset.confirmModalBypass === "true") {
            delete trigger.dataset.confirmModalBypass
            return
        }

        event.preventDefault()

        this.trigger = trigger
        this.previousFocus = document.activeElement

        const {
            confirmModalTitle,
            confirmModalMessage,
            confirmModalConfirmText,
            confirmModalCancelText,
            confirmModalConfirmClass,
            confirmModalCancelClass
        } = trigger.dataset

        this.titleTarget.textContent = confirmModalTitle || this.defaultTitleValue
        this.messageTarget.textContent = confirmModalMessage || this.defaultMessageValue
        this.confirmButtonTarget.textContent = confirmModalConfirmText || this.defaultConfirmTextValue
        this.cancelButtonTarget.textContent = confirmModalCancelText || this.defaultCancelTextValue

        this.confirmButtonTarget.className = confirmModalConfirmClass || this.confirmButtonBaseClass
        this.cancelButtonTarget.className = confirmModalCancelClass || this.cancelButtonBaseClass

        this.open()
    }

    open() {
        if (this.isOpen()) return

        this.backdropTarget.hidden = false
        requestAnimationFrame(() => {
            this.backdropTarget.classList.add("is-visible")
            this.confirmButtonTarget.focus()
        })
    }

    close() {
        if (!this.isOpen()) return

        this.backdropTarget.classList.remove("is-visible")
        const handleTransitionEnd = () => {
            this.backdropTarget.hidden = true
            this.backdropTarget.removeEventListener("transitionend", handleTransitionEnd)
        }
        this.backdropTarget.addEventListener("transitionend", handleTransitionEnd)

        if (this.previousFocus && typeof this.previousFocus.focus === "function") {
            this.previousFocus.focus()
        }

        this.trigger = null
    }

    confirm(event) {
        event.preventDefault()
        const trigger = this.trigger
        this.close()

        if (!trigger) return

        trigger.dataset.confirmModalBypass = "true"

        if ((trigger.tagName === "BUTTON" || trigger.tagName === "INPUT") && trigger.type === "submit" && trigger.form) {
            trigger.form.requestSubmit(trigger)
        } else if ((trigger.tagName === "BUTTON" || trigger.tagName === "INPUT") && trigger.form) {
            trigger.form.requestSubmit(trigger)
        } else if (trigger.tagName === "FORM") {
            trigger.requestSubmit()
        } else {
            trigger.click()
        }
    }

    cancel(event) {
        event.preventDefault()
        this.close()
    }

    handleKeydown(event) {
        if (!this.isOpen()) return

        if (event.key === "Escape") {
            event.preventDefault()
            this.close()
        }
    }

    isOpen() {
        return !this.backdropTarget.hidden
    }
}

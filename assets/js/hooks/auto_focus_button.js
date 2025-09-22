export default {
  mounted() {
    // Focus the button when it's mounted
    this.el.focus()

    // Add event listener for the Enter key
    this.handleKeyPress = (event) => {
      if (event.key === 'Enter') {
        // Get the event name from data attribute
        const action = this.el.dataset.keyAction
        if (action) {
          this.pushEvent(action, {})
          event.preventDefault()
        }
      }
    }

    // Add the event listener to the document
    document.addEventListener('keydown', this.handleKeyPress)
  },

  updated() {
    // Re-focus the button when it's updated
    this.el.focus()
  },

  destroyed() {
    // Clean up the event listener when the component is destroyed
    document.removeEventListener('keydown', this.handleKeyPress)
  }
}

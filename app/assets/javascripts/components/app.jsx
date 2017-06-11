class App extends React.Component {
    render() {
        const { current_user } = this.props

        if (current_user) {
            return <span>Ohai {current_user.email}! <a href="/signout">Sign out</a></span>
        } else {
            return <span>Ohai. Who are you? <a href="/auth/google_oauth2">Sign in with Google</a></span>
        }
    }
}
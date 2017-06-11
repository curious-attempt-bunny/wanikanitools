class App extends React.Component {
    renderAuthButton() {
        const { current_user } = this.props

        if (current_user) {
            return (
                <form className="navbar-form navbar-right" method="get" action="/signout">
                    <button type="submit" className="btn btn-default">Sign out</button>
                </form>
            )
        } else {
            return (
                <form className="navbar-form navbar-right" method="get" action="/auth/google_oauth2">
                    <button type="submit" className="btn btn-success">Sign in with Google</button>
                </form>
            )
        }
    }

    render() {
        return (
            <div>

    <nav className="navbar navbar-inverse navbar-fixed-top">
      <div className="container">
        <div className="navbar-header">
          <button type="button" className="navbar-toggle collapsed" data-toggle="collapse" data-target="#navbar" aria-expanded="false" aria-controls="navbar">
            <span className="sr-only">Toggle navigation</span>
            <span className="icon-bar"></span>
            <span className="icon-bar"></span>
            <span className="icon-bar"></span>
          </button>
          <a className="navbar-brand" href="/">dokku-rails-omniauth-bootstrap-react</a>
        </div>
        <div id="navbar" className="navbar-collapse collapse">
          { this.renderAuthButton() }
        </div>
      </div>
    </nav>

    <div className="container">

      <hr/>

      <footer>
        
      </footer>
    </div> 

            </div>
        )
    }
}
class App extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      leaches: []
    }
  }

  renderAuthButton() {
    // no auth for now
    return <div/>

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

  componentWillMount() {
    var that = this;
    fetch('/api/v2/review_statistics')
      .then(function(response) { return response.json(); })
      .then(function(json) {
        var leaches = [];
        json.data.forEach(function(item) {
          var guesses_total = item.data.meaning_correct + item.data.meaning_incorrect + item.data.reading_correct + item.data.reading_incorrect;
          if (guesses_total > 0) {
            var score = (item.data.meaning_correct + item.data.reading_correct) / (guesses_total + 1.0);
            var identifier = item.data.subject.data.character || item.data.subject.data.slug || item.data.subject.data.characters;
            var primary_reading;
            if (item.data.subject.data.readings) {
              primary_reading = item.data.subject.data.readings.filter(function(reading) { return reading.primary; })[0].reading;
            }
            var primary_meaning = item.data.subject.data.meanings.filter(function(meaning) { return meaning.primary; })[0].meaning;
            var leach = {
              id: item.data.subject_id,
              identifier: item.data.subject.data.character_images && item.data.subject.data.character_images.length > 0 ? null : identifier,
              images: item.data.subject.data.character_images,
              score: score,
              primary_reading: primary_reading,
              primary_meaning: primary_meaning,
              type: item.data.subject_type
            }
            console.log(leach, item);
            leaches.push(leach);
          }
        });
        leaches = leaches.sort(function(a,b) { return a.score - b.score; });
        that.setState({leaches: leaches.slice(0,100)});
      });
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
        <a className="navbar-brand" href="/">WaniKaniTools</a>
      </div>
      <div id="navbar" className="navbar-collapse collapse">
        { this.renderAuthButton() }
      </div>
    </div>
  </nav>

  <div className="container">
    <br/><br/>
    <h1>Leaches</h1>
    <ul>
    { this.state.leaches.map(function(leach) {
      var color = 'red';
      if (leach.type == 'radical') {
        color = '#0af';
      } else if (leach.type == 'kanji') {
        color = '#f0a';
      } else if (leach.type == 'vocabulary') {
        color = '#a0f'
      }
      return <li key={leach.id}>
        <span style={{color: 'white', backgroundColor: color, padding: '.2em'}}>
          {leach.identifier ? leach.identifier : <img src={leach.images[0].url} style={{height: '1em'}}/>}
        </span>&nbsp;
        {leach.primary_meaning}&nbsp;
        {leach.primary_reading}
      </li> })
    }
    </ul>

    <hr/>

    <footer>
      
    </footer>
  </div> 

          </div>
      )
  }
}
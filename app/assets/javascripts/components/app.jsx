class App extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      leaches: []
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
          <div style={{paddingTop: '5em'}}>

    <marquee behavior="scroll" direction="left" scrollamount="1" style={{fontSize: '10em'}}>
    { this.state.leaches.map(function(leach) {
      var color = 'red';
      if (leach.type == 'radical') {
        color = '#0af';
      } else if (leach.type == 'kanji') {
        color = '#f0a';
      } else if (leach.type == 'vocabulary') {
        color = '#a0f'
      }
      return <div key={leach.id} style={{display: 'inline-block', paddingRight: '5em', verticalAlign: 'top'}}>
        <span style={{color: 'white', backgroundColor: color, padding: '.2em'}}>
          {leach.identifier ? leach.identifier : <img src={leach.images[0].url} style={{height: '1em'}}/>}
        </span>
        <br/>
        <span style={{paddingLeft:'1em'}}>{leach.primary_meaning}</span>
        <br/>
        <span style={{paddingLeft:'2em'}}>{leach.primary_reading}</span>
      </div> })
    }
    </marquee>

          </div>
      )
  }
}
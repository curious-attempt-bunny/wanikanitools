class App extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      leaches: []
    }

    this.last_id = null;
    this.speed = 20000;
  }

  componentWillMount() {
    var that = this;
    fetch('/api/v2/review_statistics')
      .then(function(response) { return response.json(); })
      .then(function(json) {
        var leaches = [];
        json.data.forEach(function(item) {
          var guesses_total = item.data.meaning_correct + item.data.meaning_incorrect + item.data.reading_correct + item.data.reading_incorrect;
          if (guesses_total > 0 && (item.data.meaning_current_streak < 3 || (item.data.reading_current_streak < 3 && item.data.subject_type != 'radical'))) {
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
              type: item.data.subject_type,
              item: item
            }
            // console.log(leach, item);
            leaches.push(leach);
          }
        });
        leaches = leaches.sort(function(a,b) { return a.score - b.score; });
        that.setState({leaches: leaches.slice(0,100)});

        setTimeout(function() {
          that.animate();
          setInterval(function() {
            that.animate();
          }, that.speed);
        }, 0);
      });
  }

  animate() {
    if (this.state.leaches.length == 0) {
      return;
    }

    var id;
    while(true) {
      var index = Math.trunc(Math.random()*this.state.leaches.length);
      id = 'leach_'+this.state.leaches[index].id
      if (id != this.last_id) {
        break;
      }
    }

    $('.leach').removeClass('active');
    $('#'+id).addClass('active').css('left', Math.random()*500).css('top', Math.random()*500);;
    this.last_id = id;
  }

// <marquee behavior="scroll" direction="left" scrollamount="1" style={{fontSize: '10em'}}>
// </marquee>

    
  render() {
      return (
          <div className='leaches'>

    { this.state.leaches.map(function(leach) {
      return <div id={'leach_'+leach.id} key={leach.id} className='leach'>
        <span className={'type '+leach.type}>
          {leach.identifier ? leach.identifier : <img src={leach.images[0].url} style={{height: '1em'}}/>}
        </span>
        { leach.primary_reading && <br/> }
        { leach.primary_reading && <span className='reading'>{leach.primary_reading}</span> }
        <br/>
        <span className='meaning'>{leach.primary_meaning}</span>
      </div> })
    }
    
          </div>
      )
  }
}
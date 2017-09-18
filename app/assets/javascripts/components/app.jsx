
class App extends React.Component {
  constructor(props) {
    super(props);

    function qs(key) {
      key = key.replace(/[*+?^$.\[\]{}()|\\\/]/g, "\\$&"); // escape RegEx control chars
      var match = location.search.match(new RegExp("[?&]" + key + "=([^&]+)(&|$)"));
      return match && decodeURIComponent(match[1].replace(/\+/g, " "));
    }

    this.state = {
      leaches: [],
      api_key: qs('api_key'),
      error: false
    }

    this.last_id = null;
    this.speed = 20000;
  }

  componentWillMount() {
    var that = this;
    fetch('/leeches'+(this.state.api_key ? '?api_key='+this.state.api_key : ''))
      .then(function(response) {
        if (response.status != 200) {
          that.setState({error: true});
          return;
        }
        return response.json();
      }).then(function(json) {
        var leaches = [];
        json.forEach(function(item) {
          var leach = {
            id: item.subject_id,
            identifier: item.name,
            score: item.worst_score,
            primary_reading: item.primary_reading,
            primary_meaning: item.primary_meaning,
            type: item.subject_type
          }
          // console.log(leach, item);
          leaches.push(leach);
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
    setInterval(function() {
      fetch('/ping'+(that.state.api_key ? '?api_key='+that.state.api_key : '')).then(function(response) { return response.json(); }).then(function(json){});
    }, 30000);
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

  ruby(word, spelling) {
    if (!spelling) return null;

    var hiragana = 'あいうえおかがきぎくぐけげこごさざしじすずせぜそぞただちぢつづてでとどなにぬねのはばぱひびぴふぶぷへべぺほぼぽまみむめもゃやゅゆょよらりるれろわゐん';
    
    var regex = '';
    var kanji_count = 0;
    var prefixes = [];
    var kanji = [];
    var prefix = ''
    for(var i=0; i<word.length; i++) {
      if (hiragana.indexOf(word[i]) == -1) {
        if (!regex.endsWith('(.*)')) {
          regex += '(.*)';
          kanji_count += 1;
          prefixes.push(prefix);
          prefix = '';
          kanji.push(word[i]);
        } else {
          kanji[kanji.length-1] += word[i];
        }
      } else {
        regex += word[i];
        prefix += word[i];
      }
    }
    prefixes.push(prefix);

    var pattern = new RegExp(regex, 'u');
    var match = pattern.exec(spelling);
    if (!match) {
      console.log(word,'|',spelling, '**no match**');
      return null;
    }

    for(var i=0; i<kanji_count; i++) {
      if (match[i+1] == '') {
        console.log(word,'|',spelling, '**ambiguous**');
        return null;
      }
    }
    
    var html = '';
    for(var i=0; i<kanji_count; i++) {
      html += prefixes[i];
      html += '<ruby><rb>'+kanji[i]+'</rb><rt>'+match[i+1]+'</rt></ruby>';
    }
    html += prefixes[kanji_count];

    // console.log(word,'|',spelling,'|',html);

    return html;
  }

  render() {
    if (this.state.error) {
      return <div className='error'>Failed to load. Incorrect api_key perhaps?</div>
    }
    var that = this;
    return (
          <div className='leaches'>

    { this.state.leaches.map(function(leach) {
      var html = that.ruby(leach.identifier, leach.primary_reading);
      return <div id={'leach_'+leach.id} key={leach.id} className='leach'>
        <span className={'type '+leach.type}>
          {html ? <span dangerouslySetInnerHTML={{__html: html}}/> : leach.identifier ? leach.identifier : <img src={leach.images[0].url} style={{height: '1em'}}/>}
        </span>
        &nbsp;<span className='meaning'>{leach.primary_meaning}</span>
        { leach.primary_reading && !html && <br/> }
        { leach.primary_reading && !html && <span className='reading'>{leach.primary_reading}</span> }
      </div> })
    }

    { !this.state.api_key && <div className='demo-mode'>Running in demo mode - please add ?api_key=YOUR_V2_API_KEY to the URL</div> }
    { !this.state.api_key && <a href="https://github.com/curious-attempt-bunny/wanikanitools"><img style={{position: 'absolute', top: 0, left: 0, border: 0}} src="https://camo.githubusercontent.com/c6625ac1f3ee0a12250227cf83ce904423abf351/68747470733a2f2f73332e616d617a6f6e6177732e636f6d2f6769746875622f726962626f6e732f666f726b6d655f6c6566745f677261795f3664366436642e706e67" alt="Fork me on GitHub" data-canonical-src="https://s3.amazonaws.com/github/ribbons/forkme_left_gray_6d6d6d.png"/></a> }
          </div>
      )
  }
}
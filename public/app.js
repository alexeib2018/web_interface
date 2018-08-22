var app = new Vue({
  el: '#app',
  data: function() {
    return {
      login: 0,
      active: 0,
      index: '',
      days: { 0: 'Sunday',
              1: 'Monday',
              2: 'Tuesday',
              3: 'Wednesday',
              4: 'Thursday',
              5: 'Friday',
              6: 'Saturday'
      },
      locations: { 1: 'Dallas',
                   2: 'New York',
                   3: 'Chicago' },
      items: { 1: 'Item 1',
               2: 'Item 2',
               3: 'Item 3',
               4: 'Item 4' },
      data: [
        { day: 1, location: 1, item: 1, qte:  1 },
        { day: 2, location: 2, item: 2, qte:  2 },
        { day: 3, location: 3, item: 3, qte:  3 },
        { day: 4, location: 1, item: 4, qte:  4 },
        { day: 5, location: 2, item: 1, qte:  5 },
        { day: 6, location: 3, item: 2, qte:  6 },
        { day: 0, location: 1, item: 3, qte:  7 },
        { day: 1, location: 2, item: 4, qte:  8 },
        { day: 2, location: 3, item: 1, qte:  9 },
        { day: 3, location: 1, item: 2, qte: 10 },
        { day: 4, location: 2, item: 3, qte: 11 },
        { day: 5, location: 3, item: 4, qte: 12 },
        { day: 6, location: 1, item: 1, qte: 13 },
        { day: 0, location: 2, item: 2, qte: 14 },
        { day: 1, location: 1, item: 2, qte: 15 },
        { day: 2, location: 2, item: 3, qte: 16 },
        { day: 3, location: 3, item: 4, qte: 17 },
        { day: 4, location: 1, item: 1, qte: 18 },
        { day: 5, location: 2, item: 2, qte: 19 },
        { day: 6, location: 3, item: 3, qte: 20 },
        { day: 0, location: 1, item: 4, qte: 21 },
        { day: 1, location: 2, item: 1, qte: 22 },
        { day: 2, location: 3, item: 2, qte: 23 },
        { day: 3, location: 1, item: 3, qte: 24 },
        { day: 4, location: 2, item: 4, qte: 25 },
        { day: 5, location: 3, item: 1, qte: 26 },
        { day: 6, location: 1, item: 2, qte: 27 },
        { day: 0, location: 2, item: 3, qte: 28 },
      ],
      table: []
    }
  },
  methods: {
    table_by_date: function() {
      table = {}
      for(var i in this.data) {
        var data = this.data[i]
        if (table[ data.day ] === undefined) {
          table[ data.day ] = []
        }
        if ( table[ data.day ].indexOf(data.location) == -1 ) {
          table[ data.day ].push( data.location )
        }
      }
      this.table = []
      for( var i in this.days ) {
        if (table[ i ] !== undefined) {
          this.table.push( { day: i,
                             location: table[ i ] } )
        }
      }
      console.log('Day table')
    },
    table_by_location: function() {
      table = {}
      for(var i in this.data) {
        var data = this.data[i]
        if (table[ this.locations[ data.location ] ] === undefined) {
          table[ this.locations[ data.location ] ] = []
        }
        table[ this.locations[ data.location ] ].push( { item: this.items[ data.item ],
                                                         qte: data.qte,
                                                         day: this.days[ data.day ] } )
      }
      this.table = []
      for( var location in table ) {
        var row = table[location]
        this.table.push( { location: location,
                           row: row } )
      }
    },
    proc_login: function() {
      this.login = 1
      this.active = 1
      this.index = ''
    },
    proc_logout: function() {
      this.login = 0
      this.active = 0
      this.index = ''
    }
  },
  watch: {
    active: function(val) {
      if (val==1) {
        this.table_by_date()
      }
      if (val==2) {
        this.table_by_location()
      }
    }
  },
  mounted: function() {
  }
})

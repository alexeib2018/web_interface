var app = new Vue({
  el: '#app',
  data: function() {
    return {
      login: 0,
      active: 0,
      index: '',
      username: 'c0002331',
      password: 'apu1027!',
      days: { 0: 'Sunday',
              1: 'Monday',
              2: 'Tuesday',
              3: 'Wednesday',
              4: 'Thursday',
              5: 'Friday',
              6: 'Saturday'
      },
      days_low: { 0: 'sunday',
                  1: 'monday',
                  2: 'tuesday',
                  3: 'wednesday',
                  4: 'thursday',
                  5: 'friday',
                  6: 'saturday'
      },
      items: {},
      locations: {},
      orders: [],
      table: [],
      index_table: [],
      new_editfl: 0,
      new_day_saved: 0,
      new_location_saved: 0,
      new_item_saved: 0,
      new_qte_saved: 0,
      new_day: 0,
      new_location: 0,
      new_item: 0,
      new_qte: 0,
      add_location: '',
      paused: {},
      copy_day_from: 0,
      copy_day_to: 0,
      copy_location_from: 0,
      copy_location_to: 0,
      single_location: 0
    }
  },
  methods: {
    table_by_date: function() {
      this.paused = {}
      var table = {}
      for(var i in this.orders) {
        var order = this.orders[i]
        if (table[ order.day ] === undefined) {
          table[ order.day ] = []
        }
        if ( table[ order.day ].indexOf(order.location) == -1 ) {
          table[ order.day ].push( order.location )
        }

        var index = '' + order.day + '_' + order.location
        if (this.paused[index] === undefined) {
          this.paused[index] = 0
        }
        if (order.active == 0) {
          this.paused[index] = 1
        }
      }
      this.table = []
      for( var i in this.days ) {
        if (table[ i ] !== undefined) {
          this.table.push( { day: i,
                             location: table[ i ] } )
        } else {
          this.table.push( { day: i,
                             location: [] } )
        }
      }
    },
    table_by_location: function() {
      this.paused = {}
      var table = {}
      for(var i in this.orders) {
        var order = this.orders[i]
        if (table[ order.location ] === undefined) {
          table[ order.location ] = []
        }
        if ( table[ order.location ].indexOf(order.day) == -1 ) {
          table[ order.location ].push( order.day )
        }

        var index = '' + order.day + '_' + order.location
        if (this.paused[index] === undefined) {
          this.paused[index] = 0
        }
        if (order.active == 0) {
          this.paused[index] = 1
        }
      }
      this.table = []
      for( var i in this.locations ) {
        if (table[ i ] !== undefined) {
          this.table.push( { location: i,
                             days: table[ i ] } )
        } else {
          this.table.push( { location: i,
                             days: [] } )
        }
      }
    },
    index_table_collect: function() {
      var day
      var location
      var pos = this.index.indexOf('_')
      if (pos > 0) {
        day = this.index.substr(0,pos)
        location = this.index.substr(pos+1)
        this.index_table = []
        for(var i in this.orders) {
          var item = this.orders[i]
          if (item.day==day && item.location==location) {
            this.index_table.push( { id: item.item,
                                     item: this.items[item.item],
                                     qte: item.qte } )
          }
        }
      }
    },
    get_data: function() {
      var self = this
      var days = { 'sunday' : 0,
                   'monday' : 1,
                  'tuesday' : 2,
                'wednesday' : 3,
                 'thursday' : 4,
                   'friday' : 5,
                 'saturday' : 6 }
      var params = new URLSearchParams();
      params.append('name', this.username);
      params.append('password', this.password);
      axios.post('/api/get_data', params)
           .then(function(data) {
                if (data.data.account!=0) {
                  var items = data.data.items
                  self.items = {}
                  for (var item in items) {
                    self.items[ items[item].id ] = items[item].description
                  }

                  var locations = data.data.locations
                  self.locations = {}
                  for (var location in locations) {
                    if (self.single_location) {
                      if (self.single_location == locations[location].id) {
                        self.locations[ locations[location].id ] = locations[location].location
                      }
                    } else {
                      self.locations[ locations[location].id ] = locations[location].location
                    }
                  }

                  self.orders = []
                  var orders = data.data.orders
                  for (var i in orders) {
                    var order = orders[i]
                    order.day = days[order.day]
                    if (self.single_location) {
                      if (self.single_location == order.location) {
                        self.orders.push(order)
                      }
                    } else {
                      self.orders.push(order)
                    }                    
                  }

                  console.log('Data loaded ok')
                  if (self.active==1) {
                    self.table_by_date()
                  }
                  if (self.active==2) {
                    self.table_by_location()
                  }
                  self.index_table_collect()
                } else {
                  self.proc_logout()
                }
           })
    },
    proc_login: function() {
      var self=this
      var params = new URLSearchParams();
      params.append('name', this.username);
      params.append('password', this.password);
      axios.post('/api/login', params)
           .then(function(data) {
                  try {
                    if (data.data.account!=0) {
                        self.login = 1
                        self.active = 1
                        self.index = ''
                        self.get_data()
                    }
                  } catch(e) {}
              })
    },
    proc_logout: function() {
      this.login = 0
      this.active = 0
      this.index = ''
    },
    modal_item_add_show: function(day, location) {
      this.new_day = day
      this.new_location = location
      this.new_qte = 0
      $('#addItemModal').modal('show')
    },
    modal_item_add_save: function() {
      $('#addItemModal').modal('hide')
      this.order_save(this.new_day, this.new_location, this.new_item, this.new_qte, 1)
    },
    modal_order_show: function() {
      this.new_editfl = 0
      this.new_qte = 0
      $('#addOrderModal').modal('show')
    },
    modal_order_edit: function(day, location, item, qte) {
      this.new_editfl = 1
      this.new_day_saved = this.new_day = day
      this.new_location_saved = this.new_location = location
      this.new_item_saved = this.new_item = item
      this.new_qte_saved = this.new_qte = qte
      $('#addOrderModal').modal('show')
    },
    modal_order_save: function() {
      $('#addOrderModal').modal('hide')
      if (this.new_editfl) {
        if (this.new_day != this.new_day_saved ||
            this.new_location != this.new_location_saved ||
            this.new_item != this.new_item_saved) {
          var self=this
          var params = new URLSearchParams();
          params.append('name', this.username);
          params.append('password', this.password);
          params.append('day', this.days_low[this.new_day_saved]);
          params.append('location', this.new_location_saved);
          params.append('item', this.new_item_saved);
          axios.post('/api/order_delete_item', params)
               .then(function(data) {
                  self.order_save(self.new_day, self.new_location, self.new_item, self.new_qte, 1)
               })
        } else {
          if (this.new_qte != this.new_qte_saved) {
            this.order_save(this.new_day, this.new_location, this.new_item, this.new_qte, 1)
          }
        }
      } else {
        this.order_save(this.new_day, this.new_location, this.new_item, this.new_qte, 1)
      }
    },
    modal_order_copy: function() {
      this.order_save(this.new_day, this.new_location, this.new_item, this.new_qte, 1)
    },
    modal_copy_show: function(day,location) {
      this.copy_day_from = day;
      this.copy_day_to = day;
      this.copy_location_from = location;
      this.copy_location_to = location;
      $('#copyOrderModal').modal('show')
    },
    modal_copy_save: function() {
      var self=this
      var params = new URLSearchParams();
      params.append('name', this.username);
      params.append('password', this.password);
      params.append('day_from', this.days_low[this.copy_day_from]);
      params.append('location_from', this.copy_location_from);
      params.append('day_to', this.days_low[this.copy_day_to]);
      params.append('location_to', this.copy_location_to);
      axios.post('/api/copy_order', params)
           .then(function(data) {
              self.get_data()
           })
      $('#copyOrderModal').modal('hide')
    },
    activate_order: function(day, location, active) {
      var self=this
      var params = new URLSearchParams();
      params.append('name', this.username);
      params.append('password', this.password);
      params.append('day', this.days_low[day]);
      params.append('location', location);
      params.append('active', active);
      axios.post('/api/activate_order', params)
           .then(function(data) {
              self.get_data()
           })
      $('#addLocationModal').modal('hide')
      this.paused[''+day+'_'+location] = !active
      this.index_table_collect()
    },
    modal_location_show: function() {
      this.add_location = ''
      $('#addLocationModal').modal('show')
    },
    modal_location_save: function() {
      var self=this
      var params = new URLSearchParams();
      params.append('name', this.username);
      params.append('password', this.password);
      params.append('location', this.add_location);
      axios.post('/api/create_location', params)
           .then(function(data) {
              self.get_data()
           })
      $('#addLocationModal').modal('hide')
    },
    order_save: function(day,location,item,qte,active) {
      var self=this
      var params = new URLSearchParams();
      params.append('name', this.username);
      params.append('password', this.password);
      params.append('day', this.days_low[day]);
      params.append('location', location);
      params.append('item', item);
      params.append('qte', qte);
      params.append('active', active);
      axios.post('/api/order_save', params)
           .then(function(data) {
              self.get_data()
           })
    },
    delete_item: function(day,location,item) {
      var self=this
      var params = new URLSearchParams();
      params.append('name', this.username);
      params.append('password', this.password);
      params.append('day', this.days_low[day]);
      params.append('location', location);
      params.append('item', item);
      axios.post('/api/order_delete_item', params)
           .then(function(data) {
              self.get_data()
           })
    },
    set_single_location: function(location) {
      this.single_location = location
      this.get_data()
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
    },
    index: function() {
      this.index_table_collect()
    }
  },
  mounted: function() {
  }
})
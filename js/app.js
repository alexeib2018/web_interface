var app = new Vue({
  el: '#app',
  data: function() {
    return {
      login: 0,
      active: 0,
      index: '',
      username: '',
      password: '',
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
      locations_sorted: [],
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
      single_location: 0,
      login_account: '',
      login_name: '',
      login_incorrect: false,
      active_new: 1,
      show_disclaimer: 1,
      edit_location_id: 0,
      edit_location: '',
      location_invalid: false,
      delete_day: '',
      delete_location: ''
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
      var params = new FormData();
      params.append('name', this.username);
      params.append('password', this.password);
      axios.post('/cgi/app.pl?action=/api/get_data', params)
           .then(function(data) {
                if (data.data.account!=0) {
                  var items = data.data.items
                  self.items = {}
                  for (var item in items) {
                    self.items[ items[item].id ] = items[item].description.replace(/\b[a-z](?=(?:[a-z]|\W|$))/g, function($0) { return $0.toUpperCase();})
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

                  var location_names = []
                  for (var location in locations) {
                    location_names.push(locations[location].location)
                  }
                  location_names = location_names.sort()
                  self.locations_sorted = []
                  for (var i in location_names) {
                    var location_name = location_names[i]
                    for (var id in self.locations) {
                      if (self.locations[id] === location_name) {
                        self.locations_sorted.push( { id: id, location: self.locations[id] } )
                        break
                      }
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
      this.username = this.username.toLowerCase()
      this.password = this.password.toLowerCase()
      var params = new FormData();
      params.append('name', this.username);
      params.append('password', this.password);
      axios.post('/cgi/app.pl?action=/api/login', params)
           .then(function(data) {
                  try {
                    if (data.data.account!=0) {
                        self.login_account = data.data.account
                        self.login_name = data.data.name[0].name.replace(/\b[a-z](?=(?:[a-z]|\W|$))/g, function($0) { return $0.toUpperCase();})
                        self.login = 1
                        self.active = 1
                        self.index = ''
                        self.login_incorrect = false
                        self.get_data()
                    } else {
                      self.login_incorrect = true
                    }
                  } catch(e) {
                    self.login_incorrect = true
                  }
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
      this.new_qte = 0
      this.active_new = 0
      this.copy_day_from = this.new_day
      this.copy_day_to = this.new_day
      this.copy_location_from = this.new_location
      this.copy_location_to = this.new_location
      $('#addOrderModal').modal('show')
    },
    modal_order_save: function() {
      $('#addOrderModal').modal('hide')
      if (!this.active_new) {
        this.order_save(this.new_day, this.new_location, this.new_item, this.new_qte, 1)
      } else {
        var self=this
        var params = new FormData();
        params.append('name', this.username);
        params.append('password', this.password);
        params.append('day_from', this.days_low[this.copy_day_from]);
        params.append('location_from', this.copy_location_from);
        params.append('day_to', this.days_low[this.copy_day_to]);
        params.append('location_to', this.copy_location_to);
        axios.post('/cgi/app.pl?action=/api/copy_order', params)
             .then(function(data) {
                self.get_data()
             })
      }
    },
    modal_item_edit: function(day, location, item, qte) {
      this.new_day_saved = this.new_day = day
      this.new_location_saved = this.new_location = location
      this.new_item_saved = this.new_item = item
      this.new_qte_saved = this.new_qte = qte
      $('#editItemModal').modal('show')
    },
    modal_item_edit_save: function() {
      $('#editItemModal').modal('hide')
      if (this.new_day != this.new_day_saved ||
          this.new_location != this.new_location_saved ||
          this.new_item != this.new_item_saved) {
        var self=this
        var params = new FormData();
        params.append('name', this.username);
        params.append('password', this.password);
        params.append('day', this.days_low[this.new_day_saved]);
        params.append('location', this.new_location_saved);
        params.append('item', this.new_item_saved);
        axios.post('/cgi/app.pl?action=/api/order_delete_item', params)
             .then(function(data) {
                self.order_save(self.new_day, self.new_location, self.new_item, self.new_qte, 1)
             })
      } else {
        if (this.new_qte != this.new_qte_saved) {
          this.order_save(this.new_day, this.new_location, this.new_item, this.new_qte, 1)
        }
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
      var params = new FormData();
      params.append('name', this.username);
      params.append('password', this.password);
      params.append('day_from', this.days_low[this.copy_day_from]);
      params.append('location_from', this.copy_location_from);
      params.append('day_to', this.days_low[this.copy_day_to]);
      params.append('location_to', this.copy_location_to);
      axios.post('/cgi/app.pl?action=/api/copy_order', params)
           .then(function(data) {
              self.get_data()
           })
      $('#copyOrderModal').modal('hide')
    },
    activate_order: function(day, location, active) {
      var self=this
      var params = new FormData();
      params.append('name', this.username);
      params.append('password', this.password);
      params.append('day', this.days_low[day]);
      params.append('location', location);
      params.append('active', active);
      axios.post('/cgi/app.pl?action=/api/activate_order', params)
           .then(function(data) {
              self.get_data()
           })
      $('#addLocationModal').modal('hide')
      this.paused[''+day+'_'+location] = !active
      this.index_table_collect()
    },
    modal_location_show: function() {
      this.add_location = ''
      this.location_invalid = false
      $('#addLocationModal').modal('show')
    },
    modal_location_save: function(location) {
      if (!this.validate_location(location)) {
        return
      }
      var self=this
      var params = new FormData();
      params.append('name', this.username);
      params.append('password', this.password);
      params.append('location', this.add_location);
      axios.post('/cgi/app.pl?action=/api/create_location', params)
           .then(function(data) {
              self.get_data()
           })
      $('#addLocationModal').modal('hide')
    },
    modal_edit_location_show: function (id) {
      this.edit_location_id = id
      this.edit_location = this.locations[id]
      this.location_invalid = false
      $('#editLocationModal').modal('show')
    },
    modal_edit_location_save: function (location) {
      if (!this.validate_location(location)) {
        return
      }
      var self=this
      var params = new FormData();
      params.append('name', this.username);
      params.append('password', this.password);
      params.append('location_id', this.edit_location_id);
      params.append('location', this.edit_location);
      axios.post('/cgi/app.pl?action=/api/edit_location', params)
           .then(function(data) {
              self.get_data()
           })
      $('#editLocationModal').modal('hide')
    },
    order_save: function(day,location,item,qte,active) {
      var self=this
      var params = new FormData();
      params.append('name', this.username);
      params.append('password', this.password);
      params.append('day', this.days_low[day]);
      params.append('location', location);
      params.append('item', item);
      params.append('qte', qte);
      params.append('active', active);
      axios.post('/cgi/app.pl?action=/api/order_save', params)
           .then(function(data) {
              self.get_data()
           })
    },
    delete_order_show: function(day, location) {
      $('#deleteOrderModal').modal('show')
      this.delete_day = day
      this.delete_location = location
    },
    delete_order_confirm: function() {
      var self=this
      var params = new FormData();
      params.append('name', this.username);
      params.append('password', this.password);
      params.append('day', this.days_low[this.delete_day]);
      params.append('location', this.delete_location);
      axios.post('/cgi/app.pl?action=/api/delete_order', params)
           .then(function(data) {
              self.get_data()
           })
      $('#deleteOrderModal').modal('hide')
    },
    delete_item: function(day,location,item) {
      var self=this
      var params = new FormData();
      params.append('name', this.username);
      params.append('password', this.password);
      params.append('day', this.days_low[day]);
      params.append('location', location);
      params.append('item', item);
      axios.post('/cgi/app.pl?action=/api/order_delete_item', params)
           .then(function(data) {
              self.get_data()
           })
    },
    set_single_location: function(location) {
      this.single_location = location
      this.get_data()
    },
    show_location: function(location) {
      this.active = 2
      setTimeout( function() {
        document.getElementById('location_'+location).scrollIntoView()
      }, 100 )
    },
    validate_location: function(location) {
      if (location.length<=0 || location.length > 20) {
        this.location_invalid = true
        return false
      }
      this.location_invalid = false
      return true
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
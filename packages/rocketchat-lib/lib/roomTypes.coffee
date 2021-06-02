RocketChat.roomTypes = new class
	roomTypesOrder = []
	roomTypes = {}

	### Adds a room type to app
	@param identifier MUST BE equals to `db.rocketchat_room.t` field
	@param config
		template: template name to render on sideNav
		permissions: list of permissions to see the sideNav template
		icon: icon class
		route:
			name: route name
			action: route action function
	###
	add = (identifier, config) ->
		if roomTypes[identifier]?
			throw new Meteor.Error 'identifier-already-set', t('Room_type_identifier_already_set')

		# @TODO validate config options
		roomTypesOrder.push identifier
		roomTypes[identifier] = config

	### Sets a route for a room type
	@param roomType: room type (e.g.: c (for channels), d (for direct channels))
	@param routeName: route's name for given type
	@param dataCallback: callback for the route data. receives the whole subscription data as parameter
	###
	setRoute = (roomType, routeName, dataCallback) ->
		if routes[roomType]?
			throw new Meteor.Error 'route-callback-exists', 'Route callback for the given type already exists'

		# dataCallback ?= -> return {}

		routes[roomType] =
			name: routeName
			data: dataCallback or -> return {}

	###
	@param roomType: room type (e.g.: c (for channels), d (for direct channels))
	@param subData: the user's subscription data
	###
	getRoute = (roomType, subData) ->
		unless routes[roomType]?
			throw new Meteor.Error 'route-doesnt-exists', 'There is no route for the type: ' + roomType

		return FlowRouter.path routes[roomType].name, routes[roomType].data(subData)

	### add a type of room
	@param template: the name of the template to render on sideNav
	@param roles[]: a list of roles a user must have to see the template
	###
	addType = (template, roles = []) ->
		rooms.push
			template: template
			roles: [].concat roles

	getAllTypes = ->
		typesPermitted = []
		roomTypesOrder.forEach (type) ->
			if roomTypes[type].permissions? and RocketChat.authz.hasAtLeastOnePermission roomTypes[type].permissions
				typesPermitted.push roomTypes[type]

		return typesPermitted

	### add a publish for a room type
	@param roomType: room type (e.g.: c (for channels), d (for direct channels))
	@param callback: function that will return the publish's data
	###
	addPublish = (roomType, callback) ->
		if publishes[roomType]?
			throw new Meteor.Error 'route-publish-exists', 'Publish for the given type already exists'

		publishes[roomType] = callback

	### run the publish for a room type
	@param roomType: room type (e.g.: c (for channels), d (for direct channels))
	@param identifier: identifier of the room
	###
	runPublish = (roomType, identifier) ->
		return unless publishes[roomType]?
		return publishes[roomType].call this, identifier

	getIcon = (roomType) ->
		return icons[roomType]

	###
	@param roomType: room type (e.g.: c (for channels), d (for direct channels))
	@param iconClass: iconClass to display on sideNav
	###
	setIcon = (roomType, iconClass) ->
		icons[roomType] = iconClass

	addType: addType
	getTypes: getAllTypes

	setIcon: setIcon
	getIcon: getIcon

	setRoute: setRoute
	getRoute: getRoute

	addPublish: addPublish
	publish: runPublish

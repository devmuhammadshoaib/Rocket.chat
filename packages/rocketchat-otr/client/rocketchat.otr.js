RocketChat.OTR = new (class {
	constructor() {
		this.enabled = !!(window.crypto && window.crypto.subtle) && RocketChat.settings.get('OTR_Enable');
		this.instancesByRoomId = {};
	}

	getInstanceByRoomId(roomId) {
		var enabled, subscription;
		subscription = ChatSubscription.findOne({
			rid: roomId
		});
		if (!subscription) {
			return;
		}
		enabled = false;
		switch (subscription.t) {
			case 'd':
				enabled = RocketChat.settings.get('OTR_Enabled');
				break;
		}
		if (enabled === false) {
			return;
		}
		if (this.instancesByRoomId[roomId] == null) {
			this.instancesByRoomId[roomId] = new RocketChat.OTR.Room(Meteor.userId(), roomId);
		}
		return this.instancesByRoomId[roomId];
	}
})();

Meteor.startup(function() {
	RocketChat.Notifications.onUser('otr', (type, data) => {
		if (!data.roomId || !data.userId || data.userId === Meteor.userId()) {
			return;
		} else {
			RocketChat.OTR.getInstanceByRoomId(data.roomId).onUserStream(type, data);
		}
	});
	RocketChat.promises.add('onClientBeforeSendMessage', function(message) {
		if (message.rid && RocketChat.OTR.instancesByRoomId && RocketChat.OTR.instancesByRoomId[message.rid] && RocketChat.OTR.instancesByRoomId[message.rid].established.get()) {
			return RocketChat.OTR.instancesByRoomId[message.rid].encrypt(message);
		} else {
			return new Promise(function(resolve, reject) { resolve(message); });
		}
	}, RocketChat.promises.priority.HIGH);
	// RocketChat.promises.add('onClientBeforeRenderMessage', function(message) {
	// 	if (message.rid && RocketChat.OTR.instancesByRoomId && RocketChat.OTR.instancesByRoomId[message.rid] && RocketChat.OTR.instancesByRoomId[message.rid].established.get()) {
	// 		return RocketChat.OTR.instancesByRoomId[message.rid].decrypt(message);
	// 	} else {
	// 		return new Promise(function(resolve, reject) { resolve(message); });
	// 	}
	// }, RocketChat.promises.priority.HIGH);
});

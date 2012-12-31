(function() {
	
	var RSS = function($delegate) {
		this.delegate = $delegate;
	};

	RSS.prototype.authRequirements = function(callback) {
		callback({
			authType: "basic",
			fields: [
				{
					"name": "Feed URL",
					"type": "url",
					"identifier": "url"
				}
			]
		});
	};

	RSS.prototype.authenticate = function(params) {
		var name = PluginUtils.parseURL(params.url).domain;
		console.log('Authenticating for URL: ' + params.url);
		this.delegate.createAccount({
			name: 'two\nlines',
			identifier: params.url
		});
	};

	RSS.prototype.updatePreferences = function(callback) {
		callback({
			'interval': 900,
			'min': 600,
			'max': 3600
		});
	};

	PluginManager.registerPlugin(RSS, 'me.danpalmer.River.plugins.RSS');

})();
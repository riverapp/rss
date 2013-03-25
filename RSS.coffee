# Plugin for generic RSS feeds that will parse article titles and links into
# *Link* data items.
class RSS

	# The constructor is required and will be given a delegate that can perform
	# certain actions which are specific to this plugin.
	constructor: (delegate) ->
		@delegate = delegate


	# **authRequirements** is called by River to find out how to create a new
	# stream instance. Here we only ask for a feed url, we want it to be
	# referenced as `url` and be type checked as a valid URL.
	authRequirements: (callback) ->
		callback {
			authType: 'basic',
			fields: [
				{
					label: 'Feed URL',
					type: 'url',
					identifier: 'url'
				}
			]
		}


	# **authenticate** is called by River to find out how to create a new
	# feed instance, we can fill the name with the title of the feed, the
	# URL for the feed should be unique, and can also be stored as the secret for
	# access, although this is redundant.
	authenticate: (params) ->
		@getFeedTitle params.url, (title) =>
			@delegate.createAccount {
				name: title,
				identifier: params.url,
				secret: params.url
			}
	

	# Called by River to get a list of updates to be displayed to the user.
	#
	# Makes an HTTP request to the feed URL, parses using **DOMParser** and uses
	# XPath to find the title and URL of each article and creates a *Link* for
	# each one.
	update: (user, callback) ->
		HTTP.request {
			url: user.secret
		}, (err, response) =>
			if err
				return callback(err, null)
			parser = new DOMParser()
			doc = parser.parseFromString(response, 'text/xml')
			xmlArticles = doc.evaluate('/rss/channel/item', doc, null, XPathResult.ANY_TYPE, null)
			articles = []
			feedTitle = @parseTitleFromFeed(user.secret, response)
			while xmlArticle = xmlArticles.iterateNext()
				article = new Link()
				article.title = @getSafeNodeContent(doc, xmlArticle, 'title/text()')
				article.link = @getSafeNodeContent(doc, xmlArticle, 'link/text()')
				article.id = @getSafeNodeContent(doc, xmlArticle, 'guid/text()')
				articles.push(article)
			callback(null, articles)


	# Return the update interval preferences in seconds.
	updatePreferences: (callback) ->
		callback {
			interval: 900,
			min: 600,
			max: 3600
		}


	# Helper methods for parsing out parts of the feed content.
	getFeedTitle: (url, callback) ->
		HTTP.request {
			url: url
		}, (err, response) =>
			callback @parseTitleFromFeed(url, response)

	parseTitleFromFeed: (url, response) ->
		parser = new DOMParser()
		doc = parser.parseFromString(response, 'text/xml')
		return @getSafeNodeContent(doc, doc, '/rss/channel/title/text()')

	getSafeNodeContent: (doc, ctx, xpath) ->
		text = doc.evaluate(xpath, ctx, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null)
		if not text
			return ''
		text = text.singleNodeValue
		if not text
			return ''
		text = text.textContent
		if not text
			return ''
		return text


# All plugins must be registered with the global **PluginManager**. The
# plugin object passed should be a 'class' like object. This is easy with
# CoffeeScript. The identifier passed here must match that given in the
# plugin manifest file.
PluginManager.registerPlugin(RSS, 'me.danpalmer.River.plugins.RSS')
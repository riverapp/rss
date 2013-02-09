class RSS

	constructor: (delegate) ->
		@delegate = delegate

	authRequirements: (callback) ->
		callback {
			authType: 'basic',
			fields: [
				{
					name: 'Feed URL',
					type: 'url',
					identifier: 'url'
				}
			]
		}

	authenticate: (params) ->
		@getFeedTitle params.url, (title) =>
			@delegate.createAccount {
				name: title,
				identifier: params.url,
				secret: params.url
			}
	
	update: (user, callback) ->
		console.log('Updating Feed...')
		HTTP.request {
			url: user.secret
		}, (err, response) =>
			console.log('Got update')
			if err
				console.log('ERROR')
				return callback(err, null)
			console.log('No Error')
			parser = new DOMParser()
			doc = parser.parseFromString(response, 'text/xml')
			xmlArticles = doc.evaluate('/rss/channel/item', doc, null, XPathResult.ANY_TYPE, null)
			articles = []
			feedTitle = @parseTitleFromFeed(user.secret, response)
			while xmlArticle = xmlArticles.iterateNext()
				article = new Notification()
				article.subject = feedTitle
				article.action = @getSafeNodeContent(doc, xmlArticle, 'title/text()')
				article.id = @getSafeNodeContent(doc, xmlArticle, 'guid/text()')
				console.log(article)
				articles.push(article)
			callback(null, articles)


	updatePreferences: (callback) ->
		callback {
			interval: 900,
			min: 600,
			max: 3600
		}

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

PluginManager.registerPlugin(RSS, 'me.danpalmer.River.plugins.RSS')
Prism.languages.grimoire = {
	'comment': [
		{
			pattern: /(^|[^\\])\/\*[\s\S]*?(?:\*\/|$)/,
			lookbehind: true
		},
		{
			pattern: /(^|[^\\:])\/\/.*/,
			lookbehind: true,
			greedy: true
		}
	],
	'string': {
		pattern: /(["'])(?:\\(?:\r\n|[\s\S])|(?!\1)[^\\\r\n])*\1/,
		greedy: true
	},
	'class-name': {
		pattern: /((?:\b(?:class|interface|extends|implements|trait|instanceof|new)\s+)|(?:catch\s+\())[\w.\\]+/i,
		lookbehind: true,
		inside: {
			punctuation: /[.\\]/
		}
	},
	'keyword': /\b(?:import|public|alias|event|class|enum|where|if|unless|else|switch|select|case|default|while|do|until|for|loop|return|self|die|exit|yield|break|continue|as|try|catch|throw|defer|void|task|function|int|real|bool|string|list|channel|new|let|true|false|null|not|and|or|bit_not|bit_and|bit_or|bit_xor)\b/,
	'boolean': /\b(?:true|false)\b/,
	//'function': /[a-z0-9_]+(?=\()/i,
	'number': /\b0x[\da-f]+\b|(?:\b\d+\.?\d*|\B\.\d+)(?:e[+-]?\d+)?/i,
	'operator': /--?|\+\+?|!=?=?|<=?|>=?|==?=?|&&?|\|\|?|\?=??|\*\*?|\/|~|\^|%/,
	'punctuation': /[{}[\];(),.:]/
};
// Description:
//   Whining
//
//   A hubot script that creates an agenda for Wednesday Whining
//
// Configuration:
//   HUBOT_IDIO_WHINING_BRANCH: optional
//   HUBOT_IDIO_WHINING_ORG: optional
//   HUBOT_IDIO_WHINING_REPO: optional
//   HUBOT_IDIO_WHINING_TOKEN: required
//
// Commands:
//   hubot it's whine time - Push a whining agenda to the docs repo
//
// Author:
//   Mal Graty

'use strict'

const Octokat = require('octokat')
const octo = new Octokat({token: process.env.HUBOT_IDIO_WHINING_TOKEN})

const branch = process.env.HUBOT_IDIO_WHINING_BRANCH || 'master'
const org = process.env.HUBOT_IDIO_WHINING_ORG || 'idio'
const repo = process.env.HUBOT_IDIO_WHINING_REPO || 'docs'

const whine = (self, charizard) => {
  const now = new Date
  return octo.search.issues.fetch({q: `org:${org} is:open is:issue no:label is:private`})
    .then(r => r.items.map(i => `* ${i.user.login}: [${i.title}](${i.htmlUrl})`))
    .then(i => {
      const content = [
        `# Wednesday Whining, ${now.toDateString()}`,
        '',
        `**Charizard**: ${charizard}`,
        '',
        '### This Week\'s Whines',
        '',
        i.reverse().join('\n'),
        '',
        `-- ${self} OUT!`
      ].join('\n')

      const year = now.getFullYear()
      const date = now.toISOString().replace(/T.*/, '')
      const path = `minutes/wednesday-whining/${year}/${date}.md`

      const payload = {
        message: `Whining agenda ${date}`,
        committer: {
          name: process.env.HUBOT_IDIO_GIT_USER_NAME,
          email: process.env.HUBOT_IDIO_GIT_USER_EMAIL
        },
        content: new Buffer(content, 'utf8').toString('base64'),
        branch: branch
      }

      return octo.repos(org, repo).contents(path).add(payload)
    })
}

module.exports = robot => {
  robot.respond(/it's whine time/, msg => {
    whine(robot.name, msg.message.user.name)
      .then(res => msg.send(`Whining agenda: ${res.content.htmlUrl}`))
      .catch(err => msg.send('Agenda for today already exists!'))
  })
}

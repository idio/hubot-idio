// Description:
//   Llamame is most recent most important thing in life
//
// Commands:
//   hubot llama me - Receive a llama
//   hubot llama bomb N - get N llamas
//
// Author:
//   Mal Graty

'use strict'

const pool = [
  'https://s-media-cache-ak0.pinimg.com/736x/15/f4/fe/15f4fe970f4c819ef8cc5a220cc83220.jpg',
  'http://ep.yimg.com/ay/matrixcollectibles/llama-alpaca-earmuffs-12-plushie-5.gif',
  'https://s-media-cache-ak0.pinimg.com/736x/1f/f0/23/1ff023768d1b31f558feced39cce1363.jpg',
  'https://s-media-cache-ak0.pinimg.com/originals/0d/f4/5b/0df45b300b9246457dc55d4250ca2c73.jpg',
  'http://picture-cdn.wheretoget.it/r4t39f-l-610x610-home+accessory-llama-plushie-alpacasso-pastel-kawaii-kids+room-stuffed+animal.jpg',
  'https://s-media-cache-ak0.pinimg.com/736x/1a/a4/dd/1aa4dd0802b46df5141f88bbfe8e248a.jpg',
  'https://ae01.alicdn.com/kf/HTB1a8VCKXXXXXcCXXXXq6xXFXXXI/anime-Kawaii-Japan-Alpaca-font-b-Llama-b-font-13-16cm-font-b-Plush-b-font.jpg',
  'https://s-media-cache-ak0.pinimg.com/736x/ae/cd/f9/aecdf966f1c2fb6d78f5b08c7ad89113.jpg',
  'http://picture-cdn.wheretoget.it/61fzug-l-610x610-home+accessory-twaimz-llama-stuffed+animal-pastel-girly.jpg',
  'http://img14.deviantart.net/58d6/i/2014/340/2/4/llama_plushie__by_popcorn111-d88yixd.jpg',
  'https://s-media-cache-ak0.pinimg.com/736x/2b/b5/56/2bb55660f006f92791f6e5c0cc2a5503.jpg',
  'http://i.ebayimg.com/00/s/NTAwWDM3NQ==/z/ifIAAOxyaTxTVhwK/$_3.JPG?set_id=2',
  'https://s-media-cache-ak0.pinimg.com/originals/df/55/a5/df55a5336544873fadba56231068cb5f.jpg',
  'https://68.media.tumblr.com/33b60d3a1140cf49133a8eb3d87c5766/tumblr_o71aktF0kR1ueu5jco1_500.jpg',
  'http://tatecreate.com/images/pokemon-y-best-pokemon_105158298.jpg',
  'https://68.media.tumblr.com/0881c95abc69f3ee46e4b6e8f2ef96dd/tumblr_n77kjpKmcR1singbio1_500.jpg',
  'https://s-media-cache-ak0.pinimg.com/236x/79/57/6e/79576e996ba4ffdc18ed8da84c14b1eb.jpg',
  'https://s6.favim.com/orig/151030/adorable-aesthetic-alpaca-cute-Favim.com-3500642.png',
  'http://mywishlist.ru/pic/i/wish/orig/007/890/141.jpeg',
  'https://cdn1.thehunt.com/app/public/system/zine_images/5449688/original/b4514ff26dae45046625d1d0b2efe257.jpg',
  'https://s-media-cache-ak0.pinimg.com/736x/a0/b4/32/a0b4329210f972295631baa3a20531fe.jpg',
  'https://s-media-cache-ak0.pinimg.com/736x/b6/a3/a9/b6a3a91f86c0106136e13eccb02d151c.jpg',
  'https://d3ieicw58ybon5.cloudfront.net/ex/350.350/shop/product/1b3a8312cf244ab5a9dc15cf7d234f46.jpg',
  'https://ae01.alicdn.com/kf/HTB1.W7FIVXXXXblXpXXq6xXFXXXx/10pc-Lot-4-Colors-17cm-font-b-Good-b-font-Night-Alpaca-Japan-Alpacasso-Arpakasso-Plush.jpg',
  'https://s-media-cache-ak0.pinimg.com/736x/0d/37/d1/0d37d10a85cd96d884f8f850c8d74fc0.jpg',
  'https://s-media-cache-ak0.pinimg.com/736x/1f/cb/e4/1fcbe489907ff3cec4510e8c15c3e751.jpg',
  'https://s-media-cache-ak0.pinimg.com/originals/9d/4d/8c/9d4d8c77e33669fc3217d3837761d837.jpg',
  'https://ae01.alicdn.com/kf/HTB1bSCQIVXXXXXFXpXXq6xXFXXXY/1PCS-35CM-HOT-HOT-HOT-Rainbow-Alpaca-Plush-Toy-Japanese-Soft-Plush-Alpacasso-Baby-font-b.jpg',
  'https://s-media-cache-ak0.pinimg.com/originals/72/84/d4/7284d467b219b5ede80fd443bdf809ff.jpg'
]

module.exports = robot => {
  robot.respond(/llama me/i, msg => {
    pool.sort(() => Math.random())
    msg.send(pool[0])
  })
  robot.respond(/llama bomb(?: (\d+))?/i, msg => {
    const count = msg.match[1] || 5
    pool.sort(() => Math.random())
    pool.slice(0, count).forEach(llama => msg.send(llama))
  })
}

telegram bot for english sentence mining:

- you send it a word, it finds examples and definitions
- you send it `/all` command, it sends you a csv with each row containing `example,word,pronunciation,definition` (for every word you sent) that can be imported into anki

also a website with [kanji dict cards](https://words.copycat.fun/啓く) and [basic sentence segmentation](https://words.copycat.fun/sentence/昨日すき焼きを食べました)

#### Usage

```shell
$ git clone https://github.com/ruslandoga/sentence-mining
$ docker build ./sentence-mining -t sentence-mining
$ docker run -d \
  --name sentence-mining \
  --restart unless-stopped \
  -e TG_BOT_KEY=... \
  -e BACKBLAZE_ACCESS_KEY_ID=... \
  -e BACKBLAZE_BUCKET_NAME=... \
  -e BACKBLAZE_SECRET_ACCESS_KEY=... \
  -e SENTRY_DSN=... \
  -e SECRET_KEY_BASE=... \
  -e PHX_HOST=... \
  -e PHX_SERVER=true \
  -e PORT=9000 \
  -p 9000:9000 \
  -v sentence_mining_data:/data \
  sentence-mining
```

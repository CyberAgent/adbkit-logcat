Parser = require '../parser'
Entry = require '../entry'
Priority = require '../priority'

class Binary extends Parser
  HEADER_SIZE_V1 = 20
  HEADER_SIZE_V2_V3 = 24
  HEADER_SIZE_V4 = 28

  constructor: ->
    @buffer = new Buffer ''

  parse: (chunk) ->
    @buffer = Buffer.concat [@buffer, chunk]
    while @buffer.length > 4
      cursor = 0
      length = @buffer.readUInt16LE cursor
      cursor += 2
      skip = 0
      headerSize = @buffer.readUInt16LE(cursor)
      if headerSize == HEADER_SIZE_V4
        skip = 8
      else if headerSize == HEADER_SIZE_V2_V3
        skip = 4
      else
        headerSize = HEADER_SIZE_V1
      cursor += 2
      if @buffer.length < headerSize + length
        break
      entry = new Entry
      entry.setPid @buffer.readInt32LE cursor
      cursor += 4
      entry.setTid @buffer.readInt32LE cursor
      cursor += 4
      sec = @buffer.readInt32LE cursor
      cursor += 4
      nsec = @buffer.readInt32LE cursor
      entry.setDate new Date sec * 1000 + nsec / 1000000
      cursor += 4
      # Make sure that we don't choke if new fields are added
      cursor += skip
      data = @buffer.slice cursor, cursor + length
      cursor += length
      @buffer = @buffer.slice cursor
      this._processEntry entry, data
    if @buffer.length
      this.emit 'wait'
    else
      this.emit 'drain'
    return

  _processEntry: (entry, data) ->
    entry.setPriority data[0]
    cursor = 1
    length = data.length
    while cursor < length
      if data[cursor] is 0
        entry.setTag data.slice(1, cursor).toString()
        entry.setMessage data.slice(cursor + 1, length - 1).toString()
        @emit 'entry', entry
        return
      cursor += 1
    @emit 'error', new Error "Unprocessable entry data '#{data}'"
    return

module.exports = Binary

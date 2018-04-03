import endians
import streams
import strutils

export streams

const
    MaximumVarintBytes = 10
    WireTypeBits = 3
    WireTypeMask = (1 shl WireTypeBits) - 1

type
    ProtobufStreamObj* = object of StreamObj
        stream: Stream

    ProtobufStream* = ref ProtobufStreamObj

    Tag* = distinct uint32

    ParseError* = object of Exception

    InvalidFieldNumberError* = object of ParseError

    UnexpectedWireTypeError* = object of ParseError

    bytes* = distinct string

    WireType* {.pure.} = enum
        Varint = 0
        Fixed64 = 1
        LengthDelimited = 2
        StartGroup = 3
        EndGroup = 4
        Fixed32 = 5

    FieldType* {.pure.} = enum
        Double = 1
        Float
        Int64
        UInt64
        Int32
        Fixed64
        Fixed32
        Bool
        String
        Group
        Message
        Bytes
        UInt32
        Enum
        SFixed32
        SFixed64
        SInt32
        SInt64

proc wiretype*(ft: FieldType): WireType =
    case ft
    of FieldType.Double: result = WireType.Fixed64
    of FieldType.Float: result = WireType.Fixed32
    of FieldType.Int64: result = WireType.Varint
    of FieldType.UInt64: result = WireType.Varint
    of FieldType.Int32: result = WireType.Varint
    of FieldType.Fixed64: result = WireType.Fixed64
    of FieldType.Fixed32: result = WireType.Fixed32
    of FieldType.Bool: result = WireType.Varint
    of FieldType.String: result = WireType.LengthDelimited
    of FieldType.Group: result = WireType.LengthDelimited # ???
    of FieldType.Message: result = WireType.LengthDelimited
    of FieldType.Bytes: result = WireType.LengthDelimited
    of FieldType.UInt32: result = WireType.Varint
    of FieldType.Enum: result = WireType.Varint
    of FieldType.SFixed32: result = WireType.Fixed32
    of FieldType.SFixed64: result = WireType.Fixed64
    of FieldType.SInt32: result = WireType.Varint
    of FieldType.SInt64: result = WireType.Varint

proc isNumeric*(wiretype: WireType): bool =
    case wiretype
    of WireType.Varint: result = true
    of WireType.Fixed64: result = true
    of WireType.Fixed32: result = true
    else: result = false

proc isNumeric*(ft: FieldType): bool =
    result = isNumeric(wiretype(ft))

proc pbClose(s: Stream) =
    close(ProtobufStream(s).stream)
    ProtobufStream(s).stream = nil

proc pbAtEnd(s: Stream): bool =
    result = atEnd(ProtobufStream(s).stream)

proc pbSetPosition(s: Stream, pos: int) =
    setPosition(ProtobufStream(s).stream, pos)

proc pbGetPosition(s: Stream): int =
    result = getPosition(ProtobufStream(s).stream)

proc pbReadData(s: Stream, buffer: pointer, bufLen: int): int =
    result = readData(ProtobufStream(s).stream, buffer, bufLen)

proc pbPeekData(s: Stream, buffer: pointer, bufLen: int): int =
    result = peekData(ProtobufStream(s).stream, buffer, bufLen)

proc pbWriteData(s: Stream, buffer: pointer, bufLen: int) =
    writeData(ProtobufStream(s).stream, buffer, bufLen)

proc pbFlush(s: Stream) =
    flush(ProtobufStream(s).stream)

proc newProtobufStream*(stream: Stream): ProtobufStream =
    new(result)

    result.closeImpl = pbClose
    result.atEndImpl = pbAtEnd
    result.setPositionImpl = pbSetPosition
    result.getPositionImpl = pbGetPosition
    result.readDataImpl = pbReadData
    result.peekDataImpl = pbPeekData
    result.writeDataImpl = pbWriteData
    result.flushImpl = pbFlush

    result.stream = stream

proc readByte(stream: ProtobufStream): byte =
    result = readInt8(stream).byte

proc writeByte(stream: ProtobufStream, b: byte) =
    var x: byte
    shallowCopy(x, b)
    writeData(stream, addr(x), sizeof(x))

proc readVarint*(stream: ProtobufStream): uint64 =
    var
        count = 0

    result = 0

    while true:
        if count == MaximumVarintBytes:
            raise newException(Exception, "invalid varint (<= 10 bytes)")

        let b = readByte(stream)

        result = result or ((b.uint64 and 0x7f) shl (7 * count))

        inc(count)

        if (b and 0x80) == 0:
            break

proc writeVarint*(stream: ProtobufStream, n: uint64) =
    var value = n
    while value >= 0x80'u64:
        writeByte(stream, (value or 0x80).byte)
        value = value shr 7
    writeByte(stream, value.byte)

proc zigzagEncode*(n: int32): uint32 =
    {.emit:["result = ((NU32)n << 1) ^ (NU32)(n >> 31);"].}

proc zigzagDecode*(n: uint32): int32 =
    {.emit:["result = (NI32) ((n >> 1) ^ (~(n & 1) + 1));"].}

proc zigzagEncode*(n: int64): uint64 =
    {.emit:["result = ((NU64)n << 1) ^ (NU64)(n >> 63);"].}

proc zigzagDecode*(n: uint64): int64 =
    {.emit:["result = (NI64) ((n >> 1) ^ (~(n & 1) + 1));"].}

template makeTag*(fieldNumber: int, wireType: WireType): Tag =
    ((fieldNumber shl 3).uint32 or wireType.uint32).Tag

template getTagWireType*(tag: Tag): WireType =
    (tag.uint32 and WireTypeMask).WireType

template getTagFieldNumber*(tag: Tag): int =
    (tag.uint32 shr 3).int

proc writeTag*(stream: ProtobufStream, tag: Tag) =
    writeVarint(stream, tag.uint32)

proc writeTag*(stream: ProtobufStream, fieldNumber: int, wireType: WireType) =
    writeTag(stream, makeTag(fieldNumber, wireType))

proc readTag*(stream: ProtobufStream): Tag =
    result = readVarint(stream).Tag

proc writeInt32*(stream: ProtobufStream, n: int32) =
    writeVarint(stream, n.uint64)

proc readInt32*(stream: ProtobufStream): int32 =
    result = readVarint(stream).int32

proc writeSInt32*(stream: ProtobufStream, n: int32) =
    writeVarint(stream, zigzagEncode(n))

proc readSInt32*(stream: ProtobufStream): int32 =
    result = zigzagDecode(readVarint(stream).uint32)

proc writeUInt32*(stream: ProtobufStream, n: uint32) =
    writeVarint(stream, n)

proc readUInt32*(stream: ProtobufStream): uint32 =
    result = readVarint(stream).uint32

proc writeInt64*(stream: ProtobufStream, n: int64) =
    writeVarint(stream, n.uint64)

proc readInt64*(stream: ProtobufStream): int64 =
    result = readVarint(stream).int64

proc writeSInt64*(stream: ProtobufStream, n: int64) =
    writeVarint(stream, zigzagEncode(n))

proc readSInt64*(stream: ProtobufStream): int64 =
    result = zigzagDecode(readVarint(stream))

proc writeUInt64*(stream: ProtobufStream, n: uint64) =
    writeVarint(stream, n)

proc readUInt64*(stream: ProtobufStream): uint64 =
    result = readVarint(stream)

proc writeBool*(stream: ProtobufStream, value: bool) =
    writeVarint(stream, value.uint32)

proc readBool*(stream: ProtobufStream): bool =
    result = readVarint(stream).bool

proc writeFixed64*(stream: ProtobufStream, value: uint64) =
    var
        input = value
        output: uint64

    littleEndian64(addr(output), addr(input))

    write(stream, output)

proc readFixed64*(stream: ProtobufStream): uint64 =
    var tmp: uint64
    if readData(stream, addr(tmp), sizeof(tmp)) != sizeof(tmp):
        raise newException(IOError, "cannot read from stream")
    littleEndian64(addr(result), addr(tmp))

proc writeSFixed64*(stream: ProtobufStream, value: int64) =
    writeFixed64(stream, cast[uint64](value))

proc readSFixed64*(stream: ProtobufStream): int64 =
    result = cast[int64](readFixed64(stream))

proc writeDouble*(stream: ProtobufStream, value: float64) =
    var
        input = value
        output: float64

    littleEndian64(addr(output), addr(input))

    write(stream, output)

proc readDouble*(stream: ProtobufStream): float64 =
    var tmp: uint64
    if readData(stream, addr(tmp), sizeof(tmp)) != sizeof(tmp):
        raise newException(IOError, "cannot read from stream")
    littleEndian64(addr(result), addr(tmp))

proc writeFixed32*(stream: ProtobufStream, value: uint32) =
    var
        input = value
        output: uint32

    littleEndian32(addr(output), addr(input))

    write(stream, output)

proc readFixed32*(stream: ProtobufStream): uint32 =
    var tmp: uint32
    if readData(stream, addr(tmp), sizeof(tmp)) != sizeof(tmp):
        raise newException(IOError, "cannot read from stream")
    littleEndian32(addr(result), addr(tmp))

proc writeSFixed32*(stream: ProtobufStream, value: int32) =
    writeFixed32(stream, cast[uint32](value))

proc readSFixed32*(stream: ProtobufStream): int32 =
    result = cast[int32](readFixed32(stream))

proc writeFloat*(stream: ProtobufStream, value: float32) =
    var
        input = value
        output: float32

    littleEndian32(addr(output), addr(input))

    write(stream, output)

proc readFloat*(stream: ProtobufStream): float32 =
    var tmp: float32
    if readData(stream, addr(tmp), sizeof(tmp)) != sizeof(tmp):
        raise newException(IOError, "cannot read from stream")
    littleEndian32(addr(result), addr(tmp))

proc writeString*(stream: ProtobufStream, s: string) =
    writeUInt64(stream, len(s).uint64)
    write(stream, s)

proc writeBytes*(stream: ProtobufStream, s: bytes) =
    writeString(stream, string(s))

proc safeReadStr*(stream: Stream, size: int): string =
    result = newString(size)
    if readData(stream, addr(result[0]), size) != size:
        raise newException(IOError, "cannot read from stream")

proc readString*(stream: ProtobufStream): string =
    let size = int(readUInt64(stream))
    result = safeReadStr(stream, size)

proc readBytes*(stream: ProtobufStream): bytes =
    bytes(readString(stream))

proc readEnum*[T](stream: ProtobufStream): T =
    result = T(readUInt32(stream))

proc writeEnum*[T](stream: ProtobufStream, value: T) =
    writeUInt32(stream, uint32(value))

proc sizeOfVarint[T](value: T): uint64 =
    var tmp = uint64(value)
    while tmp >= 0x80'u64:
        tmp = tmp shr 7
        inc(result)
    inc(result)

proc packedFieldSize*[T](values: seq[T], fieldtype: FieldType): uint64 =
    case fieldtype
    of FieldType.Fixed64, FieldType.SFixed64, FieldType.Double:
        result = uint64(len(values)) * 8
    of FieldType.Fixed32, FieldType.SFixed32, FieldType.Float:
        result = uint64(len(values)) * 4
    of FieldType.Int64, FieldType.UInt64, FieldType.Int32, FieldType.Bool,
       FieldType.UInt32, FieldType.Enum:
        for value in values:
            result += sizeOfVarint(value)
    of FieldType.SInt32:
        for value in values:
            result += sizeOfVarint(zigzagEncode(int32(value)))
    of FieldType.SInt64:
        for value in values:
            result += sizeOfVarint(zigzagEncode(int64(value)))
    else:
        raise newException(Exception, "invalid fieldtype")

proc sizeOfString*(s: string): uint64 =
    result = sizeOfVarint(len(s).uint64) + len(s).uint64

proc sizeOfBytes*(s: bytes): uint64 =
    result = sizeOfString(string(s))

proc sizeOfDouble*(value: float64): uint64 =
    result = 8

proc sizeOfFloat*(value: float32): uint64 =
    result = 4

proc sizeOfInt64*(value: int64): uint64 =
    result = sizeOfVarint(value)

proc sizeOfUInt64*(value: uint64): uint64 =
    result = sizeOfVarint(value)

proc sizeOfInt32*(value: int32): uint64 =
    result = sizeOfVarint(value)

proc sizeOfFixed64*(value: uint64): uint64 =
    result = 8

proc sizeOfFixed32*(value: uint32): uint64 =
    result = 4

proc sizeOfBool*(value: bool): uint64 =
    result = sizeOfVarint(value)

proc sizeOfUInt32*(value: uint32): uint64 =
    result = sizeOfVarint(value)

proc sizeOfSFixed32*(value: int32): uint64 =
    result = 4

proc sizeOfSFixed64*(value: int64): uint64 =
    result = 8

proc sizeOfSInt32*(value: int32): uint64 =
    result = sizeOfVarint(zigzagEncode(value))

proc sizeOfSInt64*(value: int64): uint64 =
    result = sizeOfVarint(zigzagEncode(value))

proc sizeOfEnum*[T](value: T): uint64 =
    result = sizeOfUInt32(value.uint32)

proc skipField*(stream: ProtobufStream, wiretype: WireType) =
    case wiretype
    of WireType.Varint:
        discard readVarint(stream)
    of WireType.Fixed64:
        discard readFixed64(stream)
    of WireType.Fixed32:
        discard readFixed32(stream)
    of WireType.LengthDelimited:
        let size = readVarint(stream)
        discard safeReadStr(stream, int(size))
    else:
        raise newException(Exception, "unsupported wiretype: " & $wiretype)

proc expectWireType*(actual: WireType, expected: varargs[WireType]) =
    for exp in expected:
        if actual == exp:
            return
    let message = "Got wiretype " & $actual & " but expected: " &
        join(expected, ", ")
    raise newException(UnexpectedWireTypeError, message)

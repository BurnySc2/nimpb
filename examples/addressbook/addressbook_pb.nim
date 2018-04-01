# Generated by protoc_gen_nim. Do not edit!

import intsets

import protobuf/stream
import protobuf/types

import phonenumber_pb

type
    Person* = ref PersonObj
    PersonObj* = object of RootObj
        hasField: IntSet
        name: string
        id: int32
        email: string
        phones: seq[PhoneNumber]
    AddressBook* = ref AddressBookObj
    AddressBookObj* = object of RootObj
        hasField: IntSet
        people: seq[Person]

proc newPerson*(): Person =
    new(result)
    result.hasField = initIntSet()
    result.name = ""
    result.id = 0
    result.email = ""
    result.phones = @[]

proc clearname*(message: Person) =
    message.name = ""
    excl(message.hasField, 1)

proc hasname*(message: Person): bool =
    result = contains(message.hasField, 1)

proc setname*(message: Person, value: string) =
    message.name = value
    incl(message.hasField, 1)

proc name*(message: Person): string {.inline.} =
    message.name

proc `name=`*(message: Person, value: string) {.inline.} =
    setname(message, value)

proc clearid*(message: Person) =
    message.id = 0
    excl(message.hasField, 2)

proc hasid*(message: Person): bool =
    result = contains(message.hasField, 2)

proc setid*(message: Person, value: int32) =
    message.id = value
    incl(message.hasField, 2)

proc id*(message: Person): int32 {.inline.} =
    message.id

proc `id=`*(message: Person, value: int32) {.inline.} =
    setid(message, value)

proc clearemail*(message: Person) =
    message.email = ""
    excl(message.hasField, 3)

proc hasemail*(message: Person): bool =
    result = contains(message.hasField, 3)

proc setemail*(message: Person, value: string) =
    message.email = value
    incl(message.hasField, 3)

proc email*(message: Person): string {.inline.} =
    message.email

proc `email=`*(message: Person, value: string) {.inline.} =
    setemail(message, value)

proc clearphones*(message: Person) =
    message.phones = @[]
    excl(message.hasField, 4)

proc hasphones*(message: Person): bool =
    result = contains(message.hasField, 4)

proc setphones*(message: Person, value: seq[PhoneNumber]) =
    message.phones = value
    incl(message.hasField, 4)

proc addphones*(message: Person, value: PhoneNumber) =
    add(message.phones, value)
    incl(message.hasField, 4)

proc phones*(message: Person): seq[PhoneNumber] {.inline.} =
    message.phones

proc `phones=`*(message: Person, value: seq[PhoneNumber]) {.inline.} =
    setphones(message, value)

proc sizeOfPerson*(message: Person): uint64 =
    if hasname(message):
        let
            sizeOfField = sizeOfString(message.name)
            sizeOfTag = sizeOfUInt32(uint32(makeTag(1, WireType.LengthDelimited)))
        result = result + sizeOfField + sizeOfTag
    if hasid(message):
        let
            sizeOfField = sizeOfInt32(message.id)
            sizeOfTag = sizeOfUInt32(uint32(makeTag(2, WireType.Varint)))
        result = result + sizeOfField + sizeOfTag
    if hasemail(message):
        let
            sizeOfField = sizeOfString(message.email)
            sizeOfTag = sizeOfUInt32(uint32(makeTag(3, WireType.LengthDelimited)))
        result = result + sizeOfField + sizeOfTag
    for value in message.phones:
        let
            sizeOfValue = sizeOfPhoneNumber(value)
            sizeOfTag = sizeOfUInt32(uint32(makeTag(4, WireType.LengthDelimited)))
        result = result + sizeOfValue + sizeOfTag
    
        result = result + sizeOfUInt64(sizeOfValue)

proc writePerson*(stream: ProtobufStream, message: Person) =
    if hasname(message):
        writeTag(stream, 1, WireType.LengthDelimited)
        writeString(stream, message.name)
    if hasid(message):
        writeTag(stream, 2, WireType.Varint)
        writeInt32(stream, message.id)
    if hasemail(message):
        writeTag(stream, 3, WireType.LengthDelimited)
        writeString(stream, message.email)
    for value in message.phones:
        writeTag(stream, 4, WireType.LengthDelimited)
        writeVarint(stream, sizeOfPhoneNumber(value))
        writePhoneNumber(stream, value)

proc readPerson*(stream: ProtobufStream): Person =
    result = newPerson()
    while not atEnd(stream):
        let
            tag = readTag(stream)
            wireType = getTagWireType(tag)
        case getTagFieldNumber(tag)
        of 1:
            setname(result, readString(stream))
        of 2:
            setid(result, readInt32(stream))
        of 3:
            setemail(result, readString(stream))
        of 4:
            let
                size = readVarint(stream)
                data = readStr(stream, int(size))
                pbs = newProtobufStream(newStringStream(data))
            addphones(result, readPhoneNumber(pbs))
        else: skipField(stream, wireType)

proc serialize*(message: Person): string =
    let
        ss = newStringStream()
        pbs = newProtobufStream(ss)
    writePerson(pbs, message)
    result = ss.data

proc newPerson*(data: string): Person =
    let
        ss = newStringStream(data)
        pbs = newProtobufStream(ss)
    result = readPerson(pbs)


proc newAddressBook*(): AddressBook =
    new(result)
    result.hasField = initIntSet()
    result.people = @[]

proc clearpeople*(message: AddressBook) =
    message.people = @[]
    excl(message.hasField, 1)

proc haspeople*(message: AddressBook): bool =
    result = contains(message.hasField, 1)

proc setpeople*(message: AddressBook, value: seq[Person]) =
    message.people = value
    incl(message.hasField, 1)

proc addpeople*(message: AddressBook, value: Person) =
    add(message.people, value)
    incl(message.hasField, 1)

proc people*(message: AddressBook): seq[Person] {.inline.} =
    message.people

proc `people=`*(message: AddressBook, value: seq[Person]) {.inline.} =
    setpeople(message, value)

proc sizeOfAddressBook*(message: AddressBook): uint64 =
    for value in message.people:
        let
            sizeOfValue = sizeOfPerson(value)
            sizeOfTag = sizeOfUInt32(uint32(makeTag(1, WireType.LengthDelimited)))
        result = result + sizeOfValue + sizeOfTag
    
        result = result + sizeOfUInt64(sizeOfValue)

proc writeAddressBook*(stream: ProtobufStream, message: AddressBook) =
    for value in message.people:
        writeTag(stream, 1, WireType.LengthDelimited)
        writeVarint(stream, sizeOfPerson(value))
        writePerson(stream, value)

proc readAddressBook*(stream: ProtobufStream): AddressBook =
    result = newAddressBook()
    while not atEnd(stream):
        let
            tag = readTag(stream)
            wireType = getTagWireType(tag)
        case getTagFieldNumber(tag)
        of 1:
            let
                size = readVarint(stream)
                data = readStr(stream, int(size))
                pbs = newProtobufStream(newStringStream(data))
            addpeople(result, readPerson(pbs))
        else: skipField(stream, wireType)

proc serialize*(message: AddressBook): string =
    let
        ss = newStringStream()
        pbs = newProtobufStream(ss)
    writeAddressBook(pbs, message)
    result = ss.data

proc newAddressBook*(data: string): AddressBook =
    let
        ss = newStringStream(data)
        pbs = newProtobufStream(ss)
    result = readAddressBook(pbs)



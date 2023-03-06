const Exported = {};

! function r(e, n, t) {
    function o(i, f) {
        if (!n[i]) {
            if (!e[i]) {
                var c = "function" == typeof require && require;
                if (!f && c) return c(i, !0);
                if (u) return u(i, !0);
                throw (f = new Error("Cannot find module '" + i + "'")).code = "MODULE_NOT_FOUND", f
            }
            c = n[i] = {
                exports: {}
            }, e[i][0].call(c.exports, function(r) {
                return o(e[i][1][r] || r)
            }, c, c.exports, r, e, n, t)
        }
        return n[i].exports
    }
    for (var u = "function" == typeof require && require, i = 0; i < t.length; i++) o(t[i]);
    return o
}({
    1: [function(require, module, exports) {
        "use strict";
        exports.byteLength = function(b64) {
            var b64 = getLens(b64),
                validLen = b64[0],
                b64 = b64[1];
            return 3 * (validLen + b64) / 4 - b64
        }, exports.toByteArray = function(b64) {
            var tmp, i, lens = getLens(b64),
                validLen = lens[0],
                lens = lens[1],
                arr = new Arr(function(validLen, placeHoldersLen) {
                    return 3 * (validLen + placeHoldersLen) / 4 - placeHoldersLen
                }(validLen, lens)),
                curByte = 0,
                len = 0 < lens ? validLen - 4 : validLen;
            for (i = 0; i < len; i += 4) tmp = revLookup[b64.charCodeAt(i)] << 18 | revLookup[b64.charCodeAt(i + 1)] << 12 | revLookup[b64.charCodeAt(i + 2)] << 6 | revLookup[b64.charCodeAt(i + 3)], arr[curByte++] = tmp >> 16 & 255, arr[curByte++] = tmp >> 8 & 255, arr[curByte++] = 255 & tmp;
            2 === lens && (tmp = revLookup[b64.charCodeAt(i)] << 2 | revLookup[b64.charCodeAt(i + 1)] >> 4, arr[curByte++] = 255 & tmp);
            1 === lens && (tmp = revLookup[b64.charCodeAt(i)] << 10 | revLookup[b64.charCodeAt(i + 1)] << 4 | revLookup[b64.charCodeAt(i + 2)] >> 2, arr[curByte++] = tmp >> 8 & 255, arr[curByte++] = 255 & tmp);
            return arr
        }, exports.fromByteArray = function(uint8) {
            for (var tmp, len = uint8.length, extraBytes = len % 3, parts = [], i = 0, len2 = len - extraBytes; i < len2; i += 16383) parts.push(function(uint8, start, end) {
                for (var tmp, output = [], i = start; i < end; i += 3) tmp = (uint8[i] << 16 & 16711680) + (uint8[i + 1] << 8 & 65280) + (255 & uint8[i + 2]), output.push(function(num) {
                    return lookup[num >> 18 & 63] + lookup[num >> 12 & 63] + lookup[num >> 6 & 63] + lookup[63 & num]
                }(tmp));
                return output.join("")
            }(uint8, i, len2 < i + 16383 ? len2 : i + 16383));
            1 == extraBytes ? (tmp = uint8[len - 1], parts.push(lookup[tmp >> 2] + lookup[tmp << 4 & 63] + "==")) : 2 == extraBytes && (tmp = (uint8[len - 2] << 8) + uint8[len - 1], parts.push(lookup[tmp >> 10] + lookup[tmp >> 4 & 63] + lookup[tmp << 2 & 63] + "="));
            return parts.join("")
        };
        for (var lookup = [], revLookup = [], Arr = "undefined" != typeof Uint8Array ? Uint8Array : Array, code = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/", i = 0, len = code.length; i < len; ++i) lookup[i] = code[i], revLookup[code.charCodeAt(i)] = i;

        function getLens(b64) {
            var len = b64.length;
            if (0 < len % 4) throw new Error("Invalid string. Length must be a multiple of 4");
            b64 = b64.indexOf("="), len = (b64 = -1 === b64 ? len : b64) === len ? 0 : 4 - b64 % 4;
            return [b64, len]
        }
        revLookup["-".charCodeAt(0)] = 62, revLookup["_".charCodeAt(0)] = 63
    }, {}],
    2: [function(require, module, exports) {}, {}],
    3: [function(require, module, exports) {
        ! function(Buffer) {
            ! function() {
                "use strict";
                var base64 = require("base64-js"),
                    ieee754 = require("ieee754"),
                    K_MAX_LENGTH = (exports.Buffer = Buffer, exports.SlowBuffer = function(length) {
                        +length != length && (length = 0);
                        return Buffer.alloc(+length)
                    }, exports.INSPECT_MAX_BYTES = 50, 2147483647);

                function createBuffer(length) {
                    if (K_MAX_LENGTH < length) throw new RangeError('The value "' + length + '" is invalid for option "size"');
                    length = new Uint8Array(length);
                    return length.__proto__ = Buffer.prototype, length
                }

                function Buffer(arg, encodingOrOffset, length) {
                    if ("number" != typeof arg) return from(arg, encodingOrOffset, length);
                    if ("string" == typeof encodingOrOffset) throw new TypeError('The "string" argument must be of type string. Received type number');
                    return allocUnsafe(arg)
                }

                function from(value, encodingOrOffset, length) {
                    if ("string" == typeof value) return function(string, encoding) {
                        "string" == typeof encoding && "" !== encoding || (encoding = "utf8");
                        if (!Buffer.isEncoding(encoding)) throw new TypeError("Unknown encoding: " + encoding);
                        var length = 0 | byteLength(string, encoding),
                            buf = createBuffer(length),
                            string = buf.write(string, encoding);
                        string !== length && (buf = buf.slice(0, string));
                        return buf
                    }(value, encodingOrOffset);
                    if (ArrayBuffer.isView(value)) return fromArrayLike(value);
                    if (null == value) throw TypeError("The first argument must be one of type string, Buffer, ArrayBuffer, Array, or Array-like Object. Received type " + typeof value);
                    if (isInstance(value, ArrayBuffer) || value && isInstance(value.buffer, ArrayBuffer)) return function(array, byteOffset, length) {
                        if (byteOffset < 0 || array.byteLength < byteOffset) throw new RangeError('"offset" is outside of buffer bounds');
                        if (array.byteLength < byteOffset + (length || 0)) throw new RangeError('"length" is outside of buffer bounds');
                        array = void 0 === byteOffset && void 0 === length ? new Uint8Array(array) : void 0 === length ? new Uint8Array(array, byteOffset) : new Uint8Array(array, byteOffset, length);
                        return array.__proto__ = Buffer.prototype, array
                    }(value, encodingOrOffset, length);
                    if ("number" == typeof value) throw new TypeError('The "value" argument must not be of type number. Received type number');
                    var valueOf = value.valueOf && value.valueOf();
                    if (null != valueOf && valueOf !== value) return Buffer.from(valueOf, encodingOrOffset, length);
                    valueOf = function(obj) {
                        {
                            var len, buf;
                            if (Buffer.isBuffer(obj)) return len = 0 | checked(obj.length), 0 !== (buf = createBuffer(len)).length && obj.copy(buf, 0, 0, len), buf
                        }
                        if (void 0 !== obj.length) return "number" != typeof obj.length || numberIsNaN(obj.length) ? createBuffer(0) : fromArrayLike(obj);
                        if ("Buffer" === obj.type && Array.isArray(obj.data)) return fromArrayLike(obj.data)
                    }(value);
                    if (valueOf) return valueOf;
                    if ("undefined" != typeof Symbol && null != Symbol.toPrimitive && "function" == typeof value[Symbol.toPrimitive]) return Buffer.from(value[Symbol.toPrimitive]("string"), encodingOrOffset, length);
                    throw new TypeError("The first argument must be one of type string, Buffer, ArrayBuffer, Array, or Array-like Object. Received type " + typeof value)
                }

                function assertSize(size) {
                    if ("number" != typeof size) throw new TypeError('"size" argument must be of type number');
                    if (size < 0) throw new RangeError('The value "' + size + '" is invalid for option "size"')
                }

                function allocUnsafe(size) {
                    return assertSize(size), createBuffer(size < 0 ? 0 : 0 | checked(size))
                }

                function fromArrayLike(array) {
                    for (var length = array.length < 0 ? 0 : 0 | checked(array.length), buf = createBuffer(length), i = 0; i < length; i += 1) buf[i] = 255 & array[i];
                    return buf
                }

                function checked(length) {
                    if (K_MAX_LENGTH <= length) throw new RangeError("Attempt to allocate Buffer larger than maximum size: 0x" + K_MAX_LENGTH.toString(16) + " bytes");
                    return 0 | length
                }

                function byteLength(string, encoding) {
                    if (Buffer.isBuffer(string)) return string.length;
                    if (ArrayBuffer.isView(string) || isInstance(string, ArrayBuffer)) return string.byteLength;
                    if ("string" != typeof string) throw new TypeError('The "string" argument must be one of type string, Buffer, or ArrayBuffer. Received type ' + typeof string);
                    var len = string.length,
                        mustMatch = 2 < arguments.length && !0 === arguments[2];
                    if (!mustMatch && 0 === len) return 0;
                    for (var loweredCase = !1;;) switch (encoding) {
                        case "ascii":
                        case "latin1":
                        case "binary":
                            return len;
                        case "utf8":
                        case "utf-8":
                            return utf8ToBytes(string).length;
                        case "ucs2":
                        case "ucs-2":
                        case "utf16le":
                        case "utf-16le":
                            return 2 * len;
                        case "hex":
                            return len >>> 1;
                        case "base64":
                            return base64ToBytes(string).length;
                        default:
                            if (loweredCase) return mustMatch ? -1 : utf8ToBytes(string).length;
                            encoding = ("" + encoding).toLowerCase(), loweredCase = !0
                    }
                }

                function slowToString(encoding, start, end) {
                    var loweredCase = !1;
                    if ((start = void 0 === start || start < 0 ? 0 : start) > this.length) return "";
                    if ((end = void 0 === end || end > this.length ? this.length : end) <= 0) return "";
                    if ((end >>>= 0) <= (start >>>= 0)) return "";
                    for (encoding = encoding || "utf8";;) switch (encoding) {
                        case "hex":
                            return function(buf, start, end) {
                                var len = buf.length;
                                (!start || start < 0) && (start = 0);
                                (!end || end < 0 || len < end) && (end = len);
                                for (var out = "", i = start; i < end; ++i) out += function(n) {
                                    return n < 16 ? "0" + n.toString(16) : n.toString(16)
                                }(buf[i]);
                                return out
                            }(this, start, end);
                        case "utf8":
                        case "utf-8":
                            return utf8Slice(this, start, end);
                        case "ascii":
                            return function(buf, start, end) {
                                var ret = "";
                                end = Math.min(buf.length, end);
                                for (var i = start; i < end; ++i) ret += String.fromCharCode(127 & buf[i]);
                                return ret
                            }(this, start, end);
                        case "latin1":
                        case "binary":
                            return function(buf, start, end) {
                                var ret = "";
                                end = Math.min(buf.length, end);
                                for (var i = start; i < end; ++i) ret += String.fromCharCode(buf[i]);
                                return ret
                            }(this, start, end);
                        case "base64":
                            return function(buf, start, end) {
                                return 0 === start && end === buf.length ? base64.fromByteArray(buf) : base64.fromByteArray(buf.slice(start, end))
                            }(this, start, end);
                        case "ucs2":
                        case "ucs-2":
                        case "utf16le":
                        case "utf-16le":
                            return function(buf, start, end) {
                                for (var bytes = buf.slice(start, end), res = "", i = 0; i < bytes.length; i += 2) res += String.fromCharCode(bytes[i] + 256 * bytes[i + 1]);
                                return res
                            }(this, start, end);
                        default:
                            if (loweredCase) throw new TypeError("Unknown encoding: " + encoding);
                            encoding = (encoding + "").toLowerCase(), loweredCase = !0
                    }
                }

                function swap(b, n, m) {
                    var i = b[n];
                    b[n] = b[m], b[m] = i
                }

                function bidirectionalIndexOf(buffer, val, byteOffset, encoding, dir) {
                    if (0 === buffer.length) return -1;
                    if ("string" == typeof byteOffset ? (encoding = byteOffset, byteOffset = 0) : 2147483647 < byteOffset ? byteOffset = 2147483647 : byteOffset < -2147483648 && (byteOffset = -2147483648), (byteOffset = (byteOffset = numberIsNaN(byteOffset = +byteOffset) ? dir ? 0 : buffer.length - 1 : byteOffset) < 0 ? buffer.length + byteOffset : byteOffset) >= buffer.length) {
                        if (dir) return -1;
                        byteOffset = buffer.length - 1
                    } else if (byteOffset < 0) {
                        if (!dir) return -1;
                        byteOffset = 0
                    }
                    if ("string" == typeof val && (val = Buffer.from(val, encoding)), Buffer.isBuffer(val)) return 0 === val.length ? -1 : arrayIndexOf(buffer, val, byteOffset, encoding, dir);
                    if ("number" == typeof val) return val &= 255, "function" == typeof Uint8Array.prototype.indexOf ? (dir ? Uint8Array.prototype.indexOf : Uint8Array.prototype.lastIndexOf).call(buffer, val, byteOffset) : arrayIndexOf(buffer, [val], byteOffset, encoding, dir);
                    throw new TypeError("val must be string, number or Buffer")
                }

                function arrayIndexOf(arr, val, byteOffset, encoding, dir) {
                    var indexSize = 1,
                        arrLength = arr.length,
                        valLength = val.length;
                    if (void 0 !== encoding && ("ucs2" === (encoding = String(encoding).toLowerCase()) || "ucs-2" === encoding || "utf16le" === encoding || "utf-16le" === encoding)) {
                        if (arr.length < 2 || val.length < 2) return -1;
                        arrLength /= indexSize = 2, valLength /= 2, byteOffset /= 2
                    }

                    function read(buf, i) {
                        return 1 === indexSize ? buf[i] : buf.readUInt16BE(i * indexSize)
                    }
                    if (dir)
                        for (var foundIndex = -1, i = byteOffset; i < arrLength; i++)
                            if (read(arr, i) === read(val, -1 === foundIndex ? 0 : i - foundIndex)) {
                                if (i - (foundIndex = -1 === foundIndex ? i : foundIndex) + 1 === valLength) return foundIndex * indexSize
                            } else - 1 !== foundIndex && (i -= i - foundIndex), foundIndex = -1;
                    else
                        for (i = byteOffset = arrLength < byteOffset + valLength ? arrLength - valLength : byteOffset; 0 <= i; i--) {
                            for (var found = !0, j = 0; j < valLength; j++)
                                if (read(arr, i + j) !== read(val, j)) {
                                    found = !1;
                                    break
                                } if (found) return i
                        }
                    return -1
                }

                function asciiWrite(buf, string, offset, length) {
                    return blitBuffer(function(str) {
                        for (var byteArray = [], i = 0; i < str.length; ++i) byteArray.push(255 & str.charCodeAt(i));
                        return byteArray
                    }(string), buf, offset, length)
                }

                function ucs2Write(buf, string, offset, length) {
                    return blitBuffer(function(str, units) {
                        for (var c, hi, byteArray = [], i = 0; i < str.length && !((units -= 2) < 0); ++i) c = str.charCodeAt(i), hi = c >> 8, byteArray.push(c % 256), byteArray.push(hi);
                        return byteArray
                    }(string, buf.length - offset), buf, offset, length)
                }

                function utf8Slice(buf, start, end) {
                    end = Math.min(buf.length, end);
                    for (var res = [], i = start; i < end;) {
                        var secondByte, thirdByte, fourthByte, tempCodePoint, firstByte = buf[i],
                            codePoint = null,
                            bytesPerSequence = 239 < firstByte ? 4 : 223 < firstByte ? 3 : 191 < firstByte ? 2 : 1;
                        if (i + bytesPerSequence <= end) switch (bytesPerSequence) {
                            case 1:
                                firstByte < 128 && (codePoint = firstByte);
                                break;
                            case 2:
                                128 == (192 & (secondByte = buf[i + 1])) && 127 < (tempCodePoint = (31 & firstByte) << 6 | 63 & secondByte) && (codePoint = tempCodePoint);
                                break;
                            case 3:
                                secondByte = buf[i + 1], thirdByte = buf[i + 2], 128 == (192 & secondByte) && 128 == (192 & thirdByte) && 2047 < (tempCodePoint = (15 & firstByte) << 12 | (63 & secondByte) << 6 | 63 & thirdByte) && (tempCodePoint < 55296 || 57343 < tempCodePoint) && (codePoint = tempCodePoint);
                                break;
                            case 4:
                                secondByte = buf[i + 1], thirdByte = buf[i + 2], fourthByte = buf[i + 3], 128 == (192 & secondByte) && 128 == (192 & thirdByte) && 128 == (192 & fourthByte) && 65535 < (tempCodePoint = (15 & firstByte) << 18 | (63 & secondByte) << 12 | (63 & thirdByte) << 6 | 63 & fourthByte) && tempCodePoint < 1114112 && (codePoint = tempCodePoint)
                        }
                        null === codePoint ? (codePoint = 65533, bytesPerSequence = 1) : 65535 < codePoint && (res.push((codePoint -= 65536) >>> 10 & 1023 | 55296), codePoint = 56320 | 1023 & codePoint), res.push(codePoint), i += bytesPerSequence
                    }
                    return function(codePoints) {
                        var len = codePoints.length;
                        if (len <= MAX_ARGUMENTS_LENGTH) return String.fromCharCode.apply(String, codePoints);
                        var res = "",
                            i = 0;
                        for (; i < len;) res += String.fromCharCode.apply(String, codePoints.slice(i, i += MAX_ARGUMENTS_LENGTH));
                        return res
                    }(res)
                }
                exports.kMaxLength = K_MAX_LENGTH, (Buffer.TYPED_ARRAY_SUPPORT = function() {
                    try {
                        var arr = new Uint8Array(1);
                        return arr.__proto__ = {
                            __proto__: Uint8Array.prototype,
                            foo: function() {
                                return 42
                            }
                        }, 42 === arr.foo()
                    } catch (e) {
                        return !1
                    }
                }()) || "undefined" == typeof console || "function" != typeof console.error || console.error("This browser lacks typed array (Uint8Array) support which is required by `buffer` v5.x. Use `buffer` v4.x if you require old browser support."), Object.defineProperty(Buffer.prototype, "parent", {
                    enumerable: !0,
                    get: function() {
                        if (Buffer.isBuffer(this)) return this.buffer
                    }
                }), Object.defineProperty(Buffer.prototype, "offset", {
                    enumerable: !0,
                    get: function() {
                        if (Buffer.isBuffer(this)) return this.byteOffset
                    }
                }), "undefined" != typeof Symbol && null != Symbol.species && Buffer[Symbol.species] === Buffer && Object.defineProperty(Buffer, Symbol.species, {
                    value: null,
                    configurable: !0,
                    enumerable: !1,
                    writable: !1
                }), Buffer.poolSize = 8192, Buffer.from = from, Buffer.prototype.__proto__ = Uint8Array.prototype, Buffer.__proto__ = Uint8Array, Buffer.alloc = function(size, fill, encoding) {
                    return assertSize(size), !(size <= 0) && void 0 !== fill ? "string" == typeof encoding ? createBuffer(size).fill(fill, encoding) : createBuffer(size).fill(fill) : createBuffer(size)
                }, Buffer.allocUnsafe = allocUnsafe, Buffer.allocUnsafeSlow = allocUnsafe, Buffer.isBuffer = function(b) {
                    return null != b && !0 === b._isBuffer && b !== Buffer.prototype
                }, Buffer.compare = function(a, b) {
                    if (isInstance(a, Uint8Array) && (a = Buffer.from(a, a.offset, a.byteLength)), isInstance(b, Uint8Array) && (b = Buffer.from(b, b.offset, b.byteLength)), !Buffer.isBuffer(a) || !Buffer.isBuffer(b)) throw new TypeError('The "buf1", "buf2" arguments must be one of type Buffer or Uint8Array');
                    if (a === b) return 0;
                    for (var x = a.length, y = b.length, i = 0, len = Math.min(x, y); i < len; ++i)
                        if (a[i] !== b[i]) {
                            x = a[i], y = b[i];
                            break
                        } return x < y ? -1 : y < x ? 1 : 0
                }, Buffer.isEncoding = function(encoding) {
                    switch (String(encoding).toLowerCase()) {
                        case "hex":
                        case "utf8":
                        case "utf-8":
                        case "ascii":
                        case "latin1":
                        case "binary":
                        case "base64":
                        case "ucs2":
                        case "ucs-2":
                        case "utf16le":
                        case "utf-16le":
                            return !0;
                        default:
                            return !1
                    }
                }, Buffer.concat = function(list, length) {
                    if (!Array.isArray(list)) throw new TypeError('"list" argument must be an Array of Buffers');
                    if (0 === list.length) return Buffer.alloc(0);
                    if (void 0 === length)
                        for (i = length = 0; i < list.length; ++i) length += list[i].length;
                    for (var buffer = Buffer.allocUnsafe(length), pos = 0, i = 0; i < list.length; ++i) {
                        var buf = list[i];
                        if (isInstance(buf, Uint8Array) && (buf = Buffer.from(buf)), !Buffer.isBuffer(buf)) throw new TypeError('"list" argument must be an Array of Buffers');
                        buf.copy(buffer, pos), pos += buf.length
                    }
                    return buffer
                }, Buffer.byteLength = byteLength, Buffer.prototype._isBuffer = !0, Buffer.prototype.swap16 = function() {
                    var len = this.length;
                    if (len % 2 != 0) throw new RangeError("Buffer size must be a multiple of 16-bits");
                    for (var i = 0; i < len; i += 2) swap(this, i, i + 1);
                    return this
                }, Buffer.prototype.swap32 = function() {
                    var len = this.length;
                    if (len % 4 != 0) throw new RangeError("Buffer size must be a multiple of 32-bits");
                    for (var i = 0; i < len; i += 4) swap(this, i, i + 3), swap(this, i + 1, i + 2);
                    return this
                }, Buffer.prototype.swap64 = function() {
                    var len = this.length;
                    if (len % 8 != 0) throw new RangeError("Buffer size must be a multiple of 64-bits");
                    for (var i = 0; i < len; i += 8) swap(this, i, i + 7), swap(this, i + 1, i + 6), swap(this, i + 2, i + 5), swap(this, i + 3, i + 4);
                    return this
                }, Buffer.prototype.toLocaleString = Buffer.prototype.toString = function() {
                    var length = this.length;
                    return 0 === length ? "" : 0 === arguments.length ? utf8Slice(this, 0, length) : slowToString.apply(this, arguments)
                }, Buffer.prototype.equals = function(b) {
                    if (Buffer.isBuffer(b)) return this === b || 0 === Buffer.compare(this, b);
                    throw new TypeError("Argument must be a Buffer")
                }, Buffer.prototype.inspect = function() {
                    var str = "",
                        max = exports.INSPECT_MAX_BYTES,
                        str = this.toString("hex", 0, max).replace(/(.{2})/g, "$1 ").trim();
                    return this.length > max && (str += " ... "), "<Buffer " + str + ">"
                }, Buffer.prototype.compare = function(target, start, end, thisStart, thisEnd) {
                    if (isInstance(target, Uint8Array) && (target = Buffer.from(target, target.offset, target.byteLength)), !Buffer.isBuffer(target)) throw new TypeError('The "target" argument must be one of type Buffer or Uint8Array. Received type ' + typeof target);
                    if (void 0 === end && (end = target ? target.length : 0), void 0 === thisStart && (thisStart = 0), void 0 === thisEnd && (thisEnd = this.length), (start = void 0 === start ? 0 : start) < 0 || end > target.length || thisStart < 0 || thisEnd > this.length) throw new RangeError("out of range index");
                    if (thisEnd <= thisStart && end <= start) return 0;
                    if (thisEnd <= thisStart) return -1;
                    if (end <= start) return 1;
                    if (this === target) return 0;
                    for (var x = (thisEnd >>>= 0) - (thisStart >>>= 0), y = (end >>>= 0) - (start >>>= 0), len = Math.min(x, y), thisCopy = this.slice(thisStart, thisEnd), targetCopy = target.slice(start, end), i = 0; i < len; ++i)
                        if (thisCopy[i] !== targetCopy[i]) {
                            x = thisCopy[i], y = targetCopy[i];
                            break
                        } return x < y ? -1 : y < x ? 1 : 0
                }, Buffer.prototype.includes = function(val, byteOffset, encoding) {
                    return -1 !== this.indexOf(val, byteOffset, encoding)
                }, Buffer.prototype.indexOf = function(val, byteOffset, encoding) {
                    return bidirectionalIndexOf(this, val, byteOffset, encoding, !0)
                }, Buffer.prototype.lastIndexOf = function(val, byteOffset, encoding) {
                    return bidirectionalIndexOf(this, val, byteOffset, encoding, !1)
                }, Buffer.prototype.write = function(string, offset, length, encoding) {
                    if (void 0 === offset) encoding = "utf8", length = this.length, offset = 0;
                    else if (void 0 === length && "string" == typeof offset) encoding = offset, length = this.length, offset = 0;
                    else {
                        if (!isFinite(offset)) throw new Error("Buffer.write(string, encoding, offset[, length]) is no longer supported");
                        offset >>>= 0, isFinite(length) ? (length >>>= 0, void 0 === encoding && (encoding = "utf8")) : (encoding = length, length = void 0)
                    }
                    var remaining = this.length - offset;
                    if ((void 0 === length || remaining < length) && (length = remaining), 0 < string.length && (length < 0 || offset < 0) || offset > this.length) throw new RangeError("Attempt to write outside buffer bounds");
                    encoding = encoding || "utf8";
                    for (var loweredCase = !1;;) switch (encoding) {
                        case "hex":
                            return function(buf, string, offset, length) {
                                offset = Number(offset) || 0;
                                var remaining = buf.length - offset;
                                (!length || remaining < (length = Number(length))) && (length = remaining), (remaining = string.length) / 2 < length && (length = remaining / 2);
                                for (var i = 0; i < length; ++i) {
                                    var parsed = parseInt(string.substr(2 * i, 2), 16);
                                    if (numberIsNaN(parsed)) return i;
                                    buf[offset + i] = parsed
                                }
                                return i
                            }(this, string, offset, length);
                        case "utf8":
                        case "utf-8":
                            return function(buf, string, offset, length) {
                                return blitBuffer(utf8ToBytes(string, buf.length - offset), buf, offset, length)
                            }(this, string, offset, length);
                        case "ascii":
                            return asciiWrite(this, string, offset, length);
                        case "latin1":
                        case "binary":
                            return asciiWrite(this, string, offset, length);
                        case "base64":
                            return function(buf, string, offset, length) {
                                return blitBuffer(base64ToBytes(string), buf, offset, length)
                            }(this, string, offset, length);
                        case "ucs2":
                        case "ucs-2":
                        case "utf16le":
                        case "utf-16le":
                            return ucs2Write(this, string, offset, length);
                        default:
                            if (loweredCase) throw new TypeError("Unknown encoding: " + encoding);
                            encoding = ("" + encoding).toLowerCase(), loweredCase = !0
                    }
                }, Buffer.prototype.toJSON = function() {
                    return {
                        type: "Buffer",
                        data: Array.prototype.slice.call(this._arr || this, 0)
                    }
                };
                var MAX_ARGUMENTS_LENGTH = 4096;

                function checkOffset(offset, ext, length) {
                    if (offset % 1 != 0 || offset < 0) throw new RangeError("offset is not uint");
                    if (length < offset + ext) throw new RangeError("Trying to access beyond buffer length")
                }

                function checkInt(buf, value, offset, ext, max, min) {
                    if (!Buffer.isBuffer(buf)) throw new TypeError('"buffer" argument must be a Buffer instance');
                    if (max < value || value < min) throw new RangeError('"value" argument is out of bounds');
                    if (offset + ext > buf.length) throw new RangeError("Index out of range")
                }

                function checkIEEE754(buf, value, offset, ext) {
                    if (offset + ext > buf.length) throw new RangeError("Index out of range");
                    if (offset < 0) throw new RangeError("Index out of range")
                }

                function writeFloat(buf, value, offset, littleEndian, noAssert) {
                    return value = +value, offset >>>= 0, noAssert || checkIEEE754(buf, 0, offset, 4), ieee754.write(buf, value, offset, littleEndian, 23, 4), offset + 4
                }

                function writeDouble(buf, value, offset, littleEndian, noAssert) {
                    return value = +value, offset >>>= 0, noAssert || checkIEEE754(buf, 0, offset, 8), ieee754.write(buf, value, offset, littleEndian, 52, 8), offset + 8
                }
                Buffer.prototype.slice = function(start, end) {
                    var len = this.length,
                        len = ((start = ~~start) < 0 ? (start += len) < 0 && (start = 0) : len < start && (start = len), (end = void 0 === end ? len : ~~end) < 0 ? (end += len) < 0 && (end = 0) : len < end && (end = len), end < start && (end = start), this.subarray(start, end));
                    return len.__proto__ = Buffer.prototype, len
                }, Buffer.prototype.readUIntLE = function(offset, byteLength, noAssert) {
                    offset >>>= 0, byteLength >>>= 0, noAssert || checkOffset(offset, byteLength, this.length);
                    for (var val = this[offset], mul = 1, i = 0; ++i < byteLength && (mul *= 256);) val += this[offset + i] * mul;
                    return val
                }, Buffer.prototype.readUIntBE = function(offset, byteLength, noAssert) {
                    offset >>>= 0, byteLength >>>= 0, noAssert || checkOffset(offset, byteLength, this.length);
                    for (var val = this[offset + --byteLength], mul = 1; 0 < byteLength && (mul *= 256);) val += this[offset + --byteLength] * mul;
                    return val
                }, Buffer.prototype.readUInt8 = function(offset, noAssert) {
                    return offset >>>= 0, noAssert || checkOffset(offset, 1, this.length), this[offset]
                }, Buffer.prototype.readUInt16LE = function(offset, noAssert) {
                    return offset >>>= 0, noAssert || checkOffset(offset, 2, this.length), this[offset] | this[offset + 1] << 8
                }, Buffer.prototype.readUInt16BE = function(offset, noAssert) {
                    return offset >>>= 0, noAssert || checkOffset(offset, 2, this.length), this[offset] << 8 | this[offset + 1]
                }, Buffer.prototype.readUInt32LE = function(offset, noAssert) {
                    return offset >>>= 0, noAssert || checkOffset(offset, 4, this.length), (this[offset] | this[offset + 1] << 8 | this[offset + 2] << 16) + 16777216 * this[offset + 3]
                }, Buffer.prototype.readUInt32BE = function(offset, noAssert) {
                    return offset >>>= 0, noAssert || checkOffset(offset, 4, this.length), 16777216 * this[offset] + (this[offset + 1] << 16 | this[offset + 2] << 8 | this[offset + 3])
                }, Buffer.prototype.readIntLE = function(offset, byteLength, noAssert) {
                    offset >>>= 0, byteLength >>>= 0, noAssert || checkOffset(offset, byteLength, this.length);
                    for (var val = this[offset], mul = 1, i = 0; ++i < byteLength && (mul *= 256);) val += this[offset + i] * mul;
                    return (mul *= 128) <= val && (val -= Math.pow(2, 8 * byteLength)), val
                }, Buffer.prototype.readIntBE = function(offset, byteLength, noAssert) {
                    offset >>>= 0, byteLength >>>= 0, noAssert || checkOffset(offset, byteLength, this.length);
                    for (var i = byteLength, mul = 1, val = this[offset + --i]; 0 < i && (mul *= 256);) val += this[offset + --i] * mul;
                    return (mul *= 128) <= val && (val -= Math.pow(2, 8 * byteLength)), val
                }, Buffer.prototype.readInt8 = function(offset, noAssert) {
                    return offset >>>= 0, noAssert || checkOffset(offset, 1, this.length), 128 & this[offset] ? -1 * (255 - this[offset] + 1) : this[offset]
                }, Buffer.prototype.readInt16LE = function(offset, noAssert) {
                    offset >>>= 0, noAssert || checkOffset(offset, 2, this.length);
                    noAssert = this[offset] | this[offset + 1] << 8;
                    return 32768 & noAssert ? 4294901760 | noAssert : noAssert
                }, Buffer.prototype.readInt16BE = function(offset, noAssert) {
                    offset >>>= 0, noAssert || checkOffset(offset, 2, this.length);
                    noAssert = this[offset + 1] | this[offset] << 8;
                    return 32768 & noAssert ? 4294901760 | noAssert : noAssert
                }, Buffer.prototype.readInt32LE = function(offset, noAssert) {
                    return offset >>>= 0, noAssert || checkOffset(offset, 4, this.length), this[offset] | this[offset + 1] << 8 | this[offset + 2] << 16 | this[offset + 3] << 24
                }, Buffer.prototype.readInt32BE = function(offset, noAssert) {
                    return offset >>>= 0, noAssert || checkOffset(offset, 4, this.length), this[offset] << 24 | this[offset + 1] << 16 | this[offset + 2] << 8 | this[offset + 3]
                }, Buffer.prototype.readFloatLE = function(offset, noAssert) {
                    return offset >>>= 0, noAssert || checkOffset(offset, 4, this.length), ieee754.read(this, offset, !0, 23, 4)
                }, Buffer.prototype.readFloatBE = function(offset, noAssert) {
                    return offset >>>= 0, noAssert || checkOffset(offset, 4, this.length), ieee754.read(this, offset, !1, 23, 4)
                }, Buffer.prototype.readDoubleLE = function(offset, noAssert) {
                    return offset >>>= 0, noAssert || checkOffset(offset, 8, this.length), ieee754.read(this, offset, !0, 52, 8)
                }, Buffer.prototype.readDoubleBE = function(offset, noAssert) {
                    return offset >>>= 0, noAssert || checkOffset(offset, 8, this.length), ieee754.read(this, offset, !1, 52, 8)
                }, Buffer.prototype.writeUIntLE = function(value, offset, byteLength, noAssert) {
                    value = +value, offset >>>= 0, byteLength >>>= 0, noAssert || checkInt(this, value, offset, byteLength, Math.pow(2, 8 * byteLength) - 1, 0);
                    var mul = 1,
                        i = 0;
                    for (this[offset] = 255 & value; ++i < byteLength && (mul *= 256);) this[offset + i] = value / mul & 255;
                    return offset + byteLength
                }, Buffer.prototype.writeUIntBE = function(value, offset, byteLength, noAssert) {
                    value = +value, offset >>>= 0, byteLength >>>= 0, noAssert || checkInt(this, value, offset, byteLength, Math.pow(2, 8 * byteLength) - 1, 0);
                    var i = byteLength - 1,
                        mul = 1;
                    for (this[offset + i] = 255 & value; 0 <= --i && (mul *= 256);) this[offset + i] = value / mul & 255;
                    return offset + byteLength
                }, Buffer.prototype.writeUInt8 = function(value, offset, noAssert) {
                    return value = +value, offset >>>= 0, noAssert || checkInt(this, value, offset, 1, 255, 0), this[offset] = 255 & value, offset + 1
                }, Buffer.prototype.writeUInt16LE = function(value, offset, noAssert) {
                    return value = +value, offset >>>= 0, noAssert || checkInt(this, value, offset, 2, 65535, 0), this[offset] = 255 & value, this[offset + 1] = value >>> 8, offset + 2
                }, Buffer.prototype.writeUInt16BE = function(value, offset, noAssert) {
                    return value = +value, offset >>>= 0, noAssert || checkInt(this, value, offset, 2, 65535, 0), this[offset] = value >>> 8, this[offset + 1] = 255 & value, offset + 2
                }, Buffer.prototype.writeUInt32LE = function(value, offset, noAssert) {
                    return value = +value, offset >>>= 0, noAssert || checkInt(this, value, offset, 4, 4294967295, 0), this[offset + 3] = value >>> 24, this[offset + 2] = value >>> 16, this[offset + 1] = value >>> 8, this[offset] = 255 & value, offset + 4
                }, Buffer.prototype.writeUInt32BE = function(value, offset, noAssert) {
                    return value = +value, offset >>>= 0, noAssert || checkInt(this, value, offset, 4, 4294967295, 0), this[offset] = value >>> 24, this[offset + 1] = value >>> 16, this[offset + 2] = value >>> 8, this[offset + 3] = 255 & value, offset + 4
                }, Buffer.prototype.writeIntLE = function(value, offset, byteLength, noAssert) {
                    value = +value, offset >>>= 0, noAssert || checkInt(this, value, offset, byteLength, (noAssert = Math.pow(2, 8 * byteLength - 1)) - 1, -noAssert);
                    var i = 0,
                        mul = 1,
                        sub = 0;
                    for (this[offset] = 255 & value; ++i < byteLength && (mul *= 256);) value < 0 && 0 === sub && 0 !== this[offset + i - 1] && (sub = 1), this[offset + i] = (value / mul >> 0) - sub & 255;
                    return offset + byteLength
                }, Buffer.prototype.writeIntBE = function(value, offset, byteLength, noAssert) {
                    value = +value, offset >>>= 0, noAssert || checkInt(this, value, offset, byteLength, (noAssert = Math.pow(2, 8 * byteLength - 1)) - 1, -noAssert);
                    var i = byteLength - 1,
                        mul = 1,
                        sub = 0;
                    for (this[offset + i] = 255 & value; 0 <= --i && (mul *= 256);) value < 0 && 0 === sub && 0 !== this[offset + i + 1] && (sub = 1), this[offset + i] = (value / mul >> 0) - sub & 255;
                    return offset + byteLength
                }, Buffer.prototype.writeInt8 = function(value, offset, noAssert) {
                    return value = +value, offset >>>= 0, noAssert || checkInt(this, value, offset, 1, 127, -128), this[offset] = 255 & (value = value < 0 ? 255 + value + 1 : value), offset + 1
                }, Buffer.prototype.writeInt16LE = function(value, offset, noAssert) {
                    return value = +value, offset >>>= 0, noAssert || checkInt(this, value, offset, 2, 32767, -32768), this[offset] = 255 & value, this[offset + 1] = value >>> 8, offset + 2
                }, Buffer.prototype.writeInt16BE = function(value, offset, noAssert) {
                    return value = +value, offset >>>= 0, noAssert || checkInt(this, value, offset, 2, 32767, -32768), this[offset] = value >>> 8, this[offset + 1] = 255 & value, offset + 2
                }, Buffer.prototype.writeInt32LE = function(value, offset, noAssert) {
                    return value = +value, offset >>>= 0, noAssert || checkInt(this, value, offset, 4, 2147483647, -2147483648), this[offset] = 255 & value, this[offset + 1] = value >>> 8, this[offset + 2] = value >>> 16, this[offset + 3] = value >>> 24, offset + 4
                }, Buffer.prototype.writeInt32BE = function(value, offset, noAssert) {
                    return value = +value, offset >>>= 0, noAssert || checkInt(this, value, offset, 4, 2147483647, -2147483648), this[offset] = (value = value < 0 ? 4294967295 + value + 1 : value) >>> 24, this[offset + 1] = value >>> 16, this[offset + 2] = value >>> 8, this[offset + 3] = 255 & value, offset + 4
                }, Buffer.prototype.writeFloatLE = function(value, offset, noAssert) {
                    return writeFloat(this, value, offset, !0, noAssert)
                }, Buffer.prototype.writeFloatBE = function(value, offset, noAssert) {
                    return writeFloat(this, value, offset, !1, noAssert)
                }, Buffer.prototype.writeDoubleLE = function(value, offset, noAssert) {
                    return writeDouble(this, value, offset, !0, noAssert)
                }, Buffer.prototype.writeDoubleBE = function(value, offset, noAssert) {
                    return writeDouble(this, value, offset, !1, noAssert)
                }, Buffer.prototype.copy = function(target, targetStart, start, end) {
                    if (!Buffer.isBuffer(target)) throw new TypeError("argument should be a Buffer");
                    if (start = start || 0, end || 0 === end || (end = this.length), targetStart >= target.length && (targetStart = target.length), (end = 0 < end && end < start ? start : end) === start) return 0;
                    if (0 === target.length || 0 === this.length) return 0;
                    if ((targetStart = targetStart || 0) < 0) throw new RangeError("targetStart out of bounds");
                    if (start < 0 || start >= this.length) throw new RangeError("Index out of range");
                    if (end < 0) throw new RangeError("sourceEnd out of bounds");
                    end > this.length && (end = this.length);
                    var len = (end = target.length - targetStart < end - start ? target.length - targetStart + start : end) - start;
                    if (this === target && "function" == typeof Uint8Array.prototype.copyWithin) this.copyWithin(targetStart, start, end);
                    else if (this === target && start < targetStart && targetStart < end)
                        for (var i = len - 1; 0 <= i; --i) target[i + targetStart] = this[i + start];
                    else Uint8Array.prototype.set.call(target, this.subarray(start, end), targetStart);
                    return len
                }, Buffer.prototype.fill = function(val, start, end, encoding) {
                    if ("string" == typeof val) {
                        if ("string" == typeof start ? (encoding = start, start = 0, end = this.length) : "string" == typeof end && (encoding = end, end = this.length), void 0 !== encoding && "string" != typeof encoding) throw new TypeError("encoding must be a string");
                        if ("string" == typeof encoding && !Buffer.isEncoding(encoding)) throw new TypeError("Unknown encoding: " + encoding);
                        var code;
                        1 === val.length && (code = val.charCodeAt(0), "utf8" === encoding && code < 128 || "latin1" === encoding) && (val = code)
                    } else "number" == typeof val && (val &= 255);
                    if (start < 0 || this.length < start || this.length < end) throw new RangeError("Out of range index");
                    var i;
                    if (!(end <= start))
                        if (start >>>= 0, end = void 0 === end ? this.length : end >>> 0, "number" == typeof(val = val || 0))
                            for (i = start; i < end; ++i) this[i] = val;
                        else {
                            var bytes = Buffer.isBuffer(val) ? val : Buffer.from(val, encoding),
                                len = bytes.length;
                            if (0 === len) throw new TypeError('The value "' + val + '" is invalid for argument "value"');
                            for (i = 0; i < end - start; ++i) this[i + start] = bytes[i % len]
                        } return this
                };
                var INVALID_BASE64_RE = /[^+/0-9A-Za-z-_]/g;

                function utf8ToBytes(string, units) {
                    units = units || 1 / 0;
                    for (var codePoint, length = string.length, leadSurrogate = null, bytes = [], i = 0; i < length; ++i) {
                        if (55295 < (codePoint = string.charCodeAt(i)) && codePoint < 57344) {
                            if (!leadSurrogate) {
                                if (56319 < codePoint) {
                                    -1 < (units -= 3) && bytes.push(239, 191, 189);
                                    continue
                                }
                                if (i + 1 === length) {
                                    -1 < (units -= 3) && bytes.push(239, 191, 189);
                                    continue
                                }
                                leadSurrogate = codePoint;
                                continue
                            }
                            if (codePoint < 56320) {
                                -1 < (units -= 3) && bytes.push(239, 191, 189), leadSurrogate = codePoint;
                                continue
                            }
                            codePoint = 65536 + (leadSurrogate - 55296 << 10 | codePoint - 56320)
                        } else leadSurrogate && -1 < (units -= 3) && bytes.push(239, 191, 189);
                        if (leadSurrogate = null, codePoint < 128) {
                            if (--units < 0) break;
                            bytes.push(codePoint)
                        } else if (codePoint < 2048) {
                            if ((units -= 2) < 0) break;
                            bytes.push(codePoint >> 6 | 192, 63 & codePoint | 128)
                        } else if (codePoint < 65536) {
                            if ((units -= 3) < 0) break;
                            bytes.push(codePoint >> 12 | 224, codePoint >> 6 & 63 | 128, 63 & codePoint | 128)
                        } else {
                            if (!(codePoint < 1114112)) throw new Error("Invalid code point");
                            if ((units -= 4) < 0) break;
                            bytes.push(codePoint >> 18 | 240, codePoint >> 12 & 63 | 128, codePoint >> 6 & 63 | 128, 63 & codePoint | 128)
                        }
                    }
                    return bytes
                }

                function base64ToBytes(str) {
                    return base64.toByteArray(function(str) {
                        if ((str = (str = str.split("=")[0]).trim().replace(INVALID_BASE64_RE, "")).length < 2) return "";
                        for (; str.length % 4 != 0;) str += "=";
                        return str
                    }(str))
                }

                function blitBuffer(src, dst, offset, length) {
                    for (var i = 0; i < length && !(i + offset >= dst.length || i >= src.length); ++i) dst[i + offset] = src[i];
                    return i
                }

                function isInstance(obj, type) {
                    return obj instanceof type || null != obj && null != obj.constructor && null != obj.constructor.name && obj.constructor.name === type.name
                }

                function numberIsNaN(obj) {
                    return obj != obj
                }
            }.call(this)
        }.call(this, require("buffer").Buffer)
    }, {
        "base64-js": 1,
        buffer: 3,
        ieee754: 7
    }],
    4: [function(require, module, exports) {
        module.exports = {
            100: "Continue",
            101: "Switching Protocols",
            102: "Processing",
            200: "OK",
            201: "Created",
            202: "Accepted",
            203: "Non-Authoritative Information",
            204: "No Content",
            205: "Reset Content",
            206: "Partial Content",
            207: "Multi-Status",
            208: "Already Reported",
            226: "IM Used",
            300: "Multiple Choices",
            301: "Moved Permanently",
            302: "Found",
            303: "See Other",
            304: "Not Modified",
            305: "Use Proxy",
            307: "Temporary Redirect",
            308: "Permanent Redirect",
            400: "Bad Request",
            401: "Unauthorized",
            402: "Payment Required",
            403: "Forbidden",
            404: "Not Found",
            405: "Method Not Allowed",
            406: "Not Acceptable",
            407: "Proxy Authentication Required",
            408: "Request Timeout",
            409: "Conflict",
            410: "Gone",
            411: "Length Required",
            412: "Precondition Failed",
            413: "Payload Too Large",
            414: "URI Too Long",
            415: "Unsupported Media Type",
            416: "Range Not Satisfiable",
            417: "Expectation Failed",
            418: "I'm a teapot",
            421: "Misdirected Request",
            422: "Unprocessable Entity",
            423: "Locked",
            424: "Failed Dependency",
            425: "Unordered Collection",
            426: "Upgrade Required",
            428: "Precondition Required",
            429: "Too Many Requests",
            431: "Request Header Fields Too Large",
            451: "Unavailable For Legal Reasons",
            500: "Internal Server Error",
            501: "Not Implemented",
            502: "Bad Gateway",
            503: "Service Unavailable",
            504: "Gateway Timeout",
            505: "HTTP Version Not Supported",
            506: "Variant Also Negotiates",
            507: "Insufficient Storage",
            508: "Loop Detected",
            509: "Bandwidth Limit Exceeded",
            510: "Not Extended",
            511: "Network Authentication Required"
        }
    }, {}],
    5: [function(require, module, exports) {
        "use strict";
        var R = "object" == typeof Reflect ? Reflect : null,
            ReflectApply = R && "function" == typeof R.apply ? R.apply : function(target, receiver, args) {
                return Function.prototype.apply.call(target, receiver, args)
            };
        var ReflectOwnKeys = R && "function" == typeof R.ownKeys ? R.ownKeys : Object.getOwnPropertySymbols ? function(target) {
                return Object.getOwnPropertyNames(target).concat(Object.getOwnPropertySymbols(target))
            } : function(target) {
                return Object.getOwnPropertyNames(target)
            },
            NumberIsNaN = Number.isNaN || function(value) {
                return value != value
            };

        function EventEmitter() {
            EventEmitter.init.call(this)
        }
        module.exports = EventEmitter, module.exports.once = function(emitter, name) {
            return new Promise(function(resolve, reject) {
                function errorListener(err) {
                    emitter.removeListener(name, resolver), reject(err)
                }

                function resolver() {
                    "function" == typeof emitter.removeListener && emitter.removeListener("error", errorListener), resolve([].slice.call(arguments))
                }
                eventTargetAgnosticAddListener(emitter, name, resolver, {
                    once: !0
                }), "error" !== name && function(emitter, handler, flags) {
                    "function" == typeof emitter.on && eventTargetAgnosticAddListener(emitter, "error", handler, flags)
                }(emitter, errorListener, {
                    once: !0
                })
            })
        }, (EventEmitter.EventEmitter = EventEmitter).prototype._events = void 0, EventEmitter.prototype._eventsCount = 0, EventEmitter.prototype._maxListeners = void 0;
        var defaultMaxListeners = 10;

        function checkListener(listener) {
            if ("function" != typeof listener) throw new TypeError('The "listener" argument must be of type Function. Received type ' + typeof listener)
        }

        function _getMaxListeners(that) {
            return void 0 === that._maxListeners ? EventEmitter.defaultMaxListeners : that._maxListeners
        }

        function _addListener(target, type, listener, prepend) {
            var events, existing;
            return checkListener(listener), void 0 === (events = target._events) ? (events = target._events = Object.create(null), target._eventsCount = 0) : (void 0 !== events.newListener && (target.emit("newListener", type, listener.listener || listener), events = target._events), existing = events[type]), void 0 === existing ? (existing = events[type] = listener, ++target._eventsCount) : ("function" == typeof existing ? existing = events[type] = prepend ? [listener, existing] : [existing, listener] : prepend ? existing.unshift(listener) : existing.push(listener), 0 < (events = _getMaxListeners(target)) && existing.length > events && !existing.warned && (existing.warned = !0, (prepend = new Error("Possible EventEmitter memory leak detected. " + existing.length + " " + String(type) + " listeners added. Use emitter.setMaxListeners() to increase limit")).name = "MaxListenersExceededWarning", prepend.emitter = target, prepend.type = type, prepend.count = existing.length, listener = prepend, console) && console.warn && console.warn(listener)), target
        }

        function _onceWrap(target, type, listener) {
            target = {
                fired: !1,
                wrapFn: void 0,
                target: target,
                type: type,
                listener: listener
            }, type = function() {
                if (!this.fired) return this.target.removeListener(this.type, this.wrapFn), this.fired = !0, 0 === arguments.length ? this.listener.call(this.target) : this.listener.apply(this.target, arguments)
            }.bind(target);
            return type.listener = listener, target.wrapFn = type
        }

        function _listeners(target, type, unwrap) {
            target = target._events;
            if (void 0 === target) return [];
            target = target[type];
            if (void 0 === target) return [];
            if ("function" == typeof target) return unwrap ? [target.listener || target] : [target];
            if (unwrap) {
                for (var arr = target, ret = new Array(arr.length), i = 0; i < ret.length; ++i) ret[i] = arr[i].listener || arr[i];
                return ret
            }
            return arrayClone(target, target.length)
        }

        function listenerCount(type) {
            var events = this._events;
            if (void 0 !== events) {
                events = events[type];
                if ("function" == typeof events) return 1;
                if (void 0 !== events) return events.length
            }
            return 0
        }

        function arrayClone(arr, n) {
            for (var copy = new Array(n), i = 0; i < n; ++i) copy[i] = arr[i];
            return copy
        }

        function eventTargetAgnosticAddListener(emitter, name, listener, flags) {
            if ("function" == typeof emitter.on) flags.once ? emitter.once(name, listener) : emitter.on(name, listener);
            else {
                if ("function" != typeof emitter.addEventListener) throw new TypeError('The "emitter" argument must be of type EventEmitter. Received type ' + typeof emitter);
                emitter.addEventListener(name, function wrapListener(arg) {
                    flags.once && emitter.removeEventListener(name, wrapListener), listener(arg)
                })
            }
        }
        Object.defineProperty(EventEmitter, "defaultMaxListeners", {
            enumerable: !0,
            get: function() {
                return defaultMaxListeners
            },
            set: function(arg) {
                if ("number" != typeof arg || arg < 0 || NumberIsNaN(arg)) throw new RangeError('The value of "defaultMaxListeners" is out of range. It must be a non-negative number. Received ' + arg + ".");
                defaultMaxListeners = arg
            }
        }), EventEmitter.init = function() {
            void 0 !== this._events && this._events !== Object.getPrototypeOf(this)._events || (this._events = Object.create(null), this._eventsCount = 0), this._maxListeners = this._maxListeners || void 0
        }, EventEmitter.prototype.setMaxListeners = function(n) {
            if ("number" != typeof n || n < 0 || NumberIsNaN(n)) throw new RangeError('The value of "n" is out of range. It must be a non-negative number. Received ' + n + ".");
            return this._maxListeners = n, this
        }, EventEmitter.prototype.getMaxListeners = function() {
            return _getMaxListeners(this)
        }, EventEmitter.prototype.emit = function(type) {
            for (var args = [], i = 1; i < arguments.length; i++) args.push(arguments[i]);
            var doError = "error" === type,
                events = this._events;
            if (void 0 !== events) doError = doError && void 0 === events.error;
            else if (!doError) return !1;
            if (doError) {
                if ((er = 0 < args.length ? args[0] : er) instanceof Error) throw er;
                doError = new Error("Unhandled error." + (er ? " (" + er.message + ")" : ""));
                throw doError.context = er, doError
            }
            var er = events[type];
            if (void 0 === er) return !1;
            if ("function" == typeof er) ReflectApply(er, this, args);
            else
                for (var len = er.length, listeners = arrayClone(er, len), i = 0; i < len; ++i) ReflectApply(listeners[i], this, args);
            return !0
        }, EventEmitter.prototype.on = EventEmitter.prototype.addListener = function(type, listener) {
            return _addListener(this, type, listener, !1)
        }, EventEmitter.prototype.prependListener = function(type, listener) {
            return _addListener(this, type, listener, !0)
        }, EventEmitter.prototype.once = function(type, listener) {
            return checkListener(listener), this.on(type, _onceWrap(this, type, listener)), this
        }, EventEmitter.prototype.prependOnceListener = function(type, listener) {
            return checkListener(listener), this.prependListener(type, _onceWrap(this, type, listener)), this
        }, EventEmitter.prototype.off = EventEmitter.prototype.removeListener = function(type, listener) {
            var list, events, position, i, originalListener;
            if (checkListener(listener), void 0 !== (events = this._events) && void 0 !== (list = events[type]))
                if (list === listener || list.listener === listener) 0 == --this._eventsCount ? this._events = Object.create(null) : (delete events[type], events.removeListener && this.emit("removeListener", type, list.listener || listener));
                else if ("function" != typeof list) {
                for (position = -1, i = list.length - 1; 0 <= i; i--)
                    if (list[i] === listener || list[i].listener === listener) {
                        originalListener = list[i].listener, position = i;
                        break
                    } if (position < 0) return this;
                0 === position ? list.shift() : function(list, index) {
                    for (; index + 1 < list.length; index++) list[index] = list[index + 1];
                    list.pop()
                }(list, position), 1 === list.length && (events[type] = list[0]), void 0 !== events.removeListener && this.emit("removeListener", type, originalListener || listener)
            }
            return this
        }, EventEmitter.prototype.removeAllListeners = function(type) {
            var listeners, events = this._events;
            if (void 0 !== events)
                if (void 0 === events.removeListener) 0 === arguments.length ? (this._events = Object.create(null), this._eventsCount = 0) : void 0 !== events[type] && (0 == --this._eventsCount ? this._events = Object.create(null) : delete events[type]);
                else if (0 === arguments.length) {
                for (var key, keys = Object.keys(events), i = 0; i < keys.length; ++i) "removeListener" !== (key = keys[i]) && this.removeAllListeners(key);
                this.removeAllListeners("removeListener"), this._events = Object.create(null), this._eventsCount = 0
            } else if ("function" == typeof(listeners = events[type])) this.removeListener(type, listeners);
            else if (void 0 !== listeners)
                for (i = listeners.length - 1; 0 <= i; i--) this.removeListener(type, listeners[i]);
            return this
        }, EventEmitter.prototype.listeners = function(type) {
            return _listeners(this, type, !0)
        }, EventEmitter.prototype.rawListeners = function(type) {
            return _listeners(this, type, !1)
        }, EventEmitter.listenerCount = function(emitter, type) {
            return "function" == typeof emitter.listenerCount ? emitter.listenerCount(type) : listenerCount.call(emitter, type)
        }, EventEmitter.prototype.listenerCount = listenerCount, EventEmitter.prototype.eventNames = function() {
            return 0 < this._eventsCount ? ReflectOwnKeys(this._events) : []
        }
    }, {}],
    6: [function(require, module, exports) {
        var key, http = require("http"),
            url = require("url"),
            https = module.exports;
        for (key in http) http.hasOwnProperty(key) && (https[key] = http[key]);

        function validateParams(params) {
            if ((params = "string" == typeof params ? url.parse(params) : params).protocol || (params.protocol = "https:"), "https:" !== params.protocol) throw new Error('Protocol "' + params.protocol + '" not supported. Expected "https:"');
            return params
        }
        https.request = function(params, cb) {
            return params = validateParams(params), http.request.call(this, params, cb)
        }, https.get = function(params, cb) {
            return params = validateParams(params), http.get.call(this, params, cb)
        }
    }, {
        http: 30,
        url: 51
    }],
    7: [function(require, module, exports) {
        exports.read = function(buffer, offset, isLE, mLen, nBytes) {
            var e, m, eLen = 8 * nBytes - mLen - 1,
                eMax = (1 << eLen) - 1,
                eBias = eMax >> 1,
                nBits = -7,
                i = isLE ? nBytes - 1 : 0,
                d = isLE ? -1 : 1,
                nBytes = buffer[offset + i];
            for (i += d, e = nBytes & (1 << -nBits) - 1, nBytes >>= -nBits, nBits += eLen; 0 < nBits; e = 256 * e + buffer[offset + i], i += d, nBits -= 8);
            for (m = e & (1 << -nBits) - 1, e >>= -nBits, nBits += mLen; 0 < nBits; m = 256 * m + buffer[offset + i], i += d, nBits -= 8);
            if (0 === e) e = 1 - eBias;
            else {
                if (e === eMax) return m ? NaN : 1 / 0 * (nBytes ? -1 : 1);
                m += Math.pow(2, mLen), e -= eBias
            }
            return (nBytes ? -1 : 1) * m * Math.pow(2, e - mLen)
        }, exports.write = function(buffer, value, offset, isLE, mLen, nBytes) {
            var e, m, eLen = 8 * nBytes - mLen - 1,
                eMax = (1 << eLen) - 1,
                eBias = eMax >> 1,
                rt = 23 === mLen ? Math.pow(2, -24) - Math.pow(2, -77) : 0,
                i = isLE ? 0 : nBytes - 1,
                d = isLE ? 1 : -1,
                nBytes = value < 0 || 0 === value && 1 / value < 0 ? 1 : 0;
            for (value = Math.abs(value), isNaN(value) || value === 1 / 0 ? (m = isNaN(value) ? 1 : 0, e = eMax) : (e = Math.floor(Math.log(value) / Math.LN2), value * (isLE = Math.pow(2, -e)) < 1 && (e--, isLE *= 2), 2 <= (value += 1 <= e + eBias ? rt / isLE : rt * Math.pow(2, 1 - eBias)) * isLE && (e++, isLE /= 2), eMax <= e + eBias ? (m = 0, e = eMax) : 1 <= e + eBias ? (m = (value * isLE - 1) * Math.pow(2, mLen), e += eBias) : (m = value * Math.pow(2, eBias - 1) * Math.pow(2, mLen), e = 0)); 8 <= mLen; buffer[offset + i] = 255 & m, i += d, m /= 256, mLen -= 8);
            for (e = e << mLen | m, eLen += mLen; 0 < eLen; buffer[offset + i] = 255 & e, i += d, e /= 256, eLen -= 8);
            buffer[offset + i - d] |= 128 * nBytes
        }
    }, {}],
    8: [function(require, module, exports) {
        "function" == typeof Object.create ? module.exports = function(ctor, superCtor) {
            superCtor && (ctor.super_ = superCtor, ctor.prototype = Object.create(superCtor.prototype, {
                constructor: {
                    value: ctor,
                    enumerable: !1,
                    writable: !0,
                    configurable: !0
                }
            }))
        } : module.exports = function(ctor, superCtor) {
            var TempCtor;
            superCtor && (ctor.super_ = superCtor, (TempCtor = function() {}).prototype = superCtor.prototype, ctor.prototype = new TempCtor, ctor.prototype.constructor = ctor)
        }
    }, {}],
    9: [function(require, module, exports) {
        var cachedSetTimeout, cachedClearTimeout, module = module.exports = {};

        function defaultSetTimout() {
            throw new Error("setTimeout has not been defined")
        }

        function defaultClearTimeout() {
            throw new Error("clearTimeout has not been defined")
        }
        try {
            cachedSetTimeout = "function" == typeof setTimeout ? setTimeout : defaultSetTimout
        } catch (e) {
            cachedSetTimeout = defaultSetTimout
        }
        try {
            cachedClearTimeout = "function" == typeof clearTimeout ? clearTimeout : defaultClearTimeout
        } catch (e) {
            cachedClearTimeout = defaultClearTimeout
        }

        function runTimeout(fun) {
            if (cachedSetTimeout === setTimeout) return setTimeout(fun, 0);
            if ((cachedSetTimeout === defaultSetTimout || !cachedSetTimeout) && setTimeout) return (cachedSetTimeout = setTimeout)(fun, 0);
            try {
                return cachedSetTimeout(fun, 0)
            } catch (e) {
                try {
                    return cachedSetTimeout.call(null, fun, 0)
                } catch (e) {
                    return cachedSetTimeout.call(this, fun, 0)
                }
            }
        }
        var currentQueue, queue = [],
            draining = !1,
            queueIndex = -1;

        function cleanUpNextTick() {
            draining && currentQueue && (draining = !1, currentQueue.length ? queue = currentQueue.concat(queue) : queueIndex = -1, queue.length) && drainQueue()
        }

        function drainQueue() {
            if (!draining) {
                for (var timeout = runTimeout(cleanUpNextTick), len = (draining = !0, queue.length); len;) {
                    for (currentQueue = queue, queue = []; ++queueIndex < len;) currentQueue && currentQueue[queueIndex].run();
                    queueIndex = -1, len = queue.length
                }
                currentQueue = null, draining = !1, ! function(marker) {
                    if (cachedClearTimeout === clearTimeout) return clearTimeout(marker);
                    if ((cachedClearTimeout === defaultClearTimeout || !cachedClearTimeout) && clearTimeout) return (cachedClearTimeout = clearTimeout)(marker);
                    try {
                        cachedClearTimeout(marker)
                    } catch (e) {
                        try {
                            return cachedClearTimeout.call(null, marker)
                        } catch (e) {
                            return cachedClearTimeout.call(this, marker)
                        }
                    }
                }(timeout)
            }
        }

        function Item(fun, array) {
            this.fun = fun, this.array = array
        }

        function noop() {}
        module.nextTick = function(fun) {
            var args = new Array(arguments.length - 1);
            if (1 < arguments.length)
                for (var i = 1; i < arguments.length; i++) args[i - 1] = arguments[i];
            queue.push(new Item(fun, args)), 1 !== queue.length || draining || runTimeout(drainQueue)
        }, Item.prototype.run = function() {
            this.fun.apply(null, this.array)
        }, module.title = "browser", module.browser = !0, module.env = {}, module.argv = [], module.version = "", module.versions = {}, module.on = noop, module.addListener = noop, module.once = noop, module.off = noop, module.removeListener = noop, module.removeAllListeners = noop, module.emit = noop, module.prependListener = noop, module.prependOnceListener = noop, module.listeners = function(name) {
            return []
        }, module.binding = function(name) {
            throw new Error("process.binding is not supported")
        }, module.cwd = function() {
            return "/"
        }, module.chdir = function(dir) {
            throw new Error("process.chdir is not supported")
        }, module.umask = function() {
            return 0
        }
    }, {}],
    10: [function(require, module, exports) {
        ! function(global) {
            ! function() {
                var root = this,
                    freeExports = "object" == typeof exports && exports && !exports.nodeType && exports,
                    freeModule = "object" == typeof module && module && !module.nodeType && module,
                    freeGlobal = "object" == typeof global && global;
                freeGlobal.global !== freeGlobal && freeGlobal.window !== freeGlobal && freeGlobal.self !== freeGlobal || (root = freeGlobal);
                var punycode, key, maxInt = 2147483647,
                    base = 36,
                    tMax = 26,
                    skew = 38,
                    damp = 700,
                    regexPunycode = /^xn--/,
                    regexNonASCII = /[^\x20-\x7E]/,
                    regexSeparators = /[\x2E\u3002\uFF0E\uFF61]/g,
                    errors = {
                        overflow: "Overflow: input needs wider integers to process",
                        "not-basic": "Illegal input >= 0x80 (not a basic code point)",
                        "invalid-input": "Invalid input"
                    },
                    baseMinusTMin = base - 1,
                    floor = Math.floor,
                    stringFromCharCode = String.fromCharCode;

                function error(type) {
                    throw new RangeError(errors[type])
                }

                function map(array, fn) {
                    for (var length = array.length, result = []; length--;) result[length] = fn(array[length]);
                    return result
                }

                function mapDomain(string, fn) {
                    var parts = string.split("@"),
                        result = "",
                        parts = (1 < parts.length && (result = parts[0] + "@", string = parts[1]), (string = string.replace(regexSeparators, ".")).split("."));
                    return result + map(parts, fn).join(".")
                }

                function ucs2decode(string) {
                    for (var value, extra, output = [], counter = 0, length = string.length; counter < length;) 55296 <= (value = string.charCodeAt(counter++)) && value <= 56319 && counter < length ? 56320 == (64512 & (extra = string.charCodeAt(counter++))) ? output.push(((1023 & value) << 10) + (1023 & extra) + 65536) : (output.push(value), counter--) : output.push(value);
                    return output
                }

                function ucs2encode(array) {
                    return map(array, function(value) {
                        var output = "";
                        return 65535 < value && (output += stringFromCharCode((value -= 65536) >>> 10 & 1023 | 55296), value = 56320 | 1023 & value), output += stringFromCharCode(value)
                    }).join("")
                }

                function digitToBasic(digit, flag) {
                    return digit + 22 + 75 * (digit < 26) - ((0 != flag) << 5)
                }

                function adapt(delta, numPoints, firstTime) {
                    var k = 0;
                    for (delta = firstTime ? floor(delta / damp) : delta >> 1, delta += floor(delta / numPoints); baseMinusTMin * tMax >> 1 < delta; k += base) delta = floor(delta / baseMinusTMin);
                    return floor(k + (baseMinusTMin + 1) * delta / (delta + skew))
                }

                function decode(input) {
                    var out, j, index, oldi, w, k, codePoint, output = [],
                        inputLength = input.length,
                        i = 0,
                        n = 128,
                        bias = 72,
                        basic = input.lastIndexOf("-");
                    for (basic < 0 && (basic = 0), j = 0; j < basic; ++j) 128 <= input.charCodeAt(j) && error("not-basic"), output.push(input.charCodeAt(j));
                    for (index = 0 < basic ? basic + 1 : 0; index < inputLength;) {
                        for (oldi = i, w = 1, k = base; inputLength <= index && error("invalid-input"), codePoint = input.charCodeAt(index++), (base <= (codePoint = codePoint - 48 < 10 ? codePoint - 22 : codePoint - 65 < 26 ? codePoint - 65 : codePoint - 97 < 26 ? codePoint - 97 : base) || codePoint > floor((maxInt - i) / w)) && error("overflow"), i += codePoint * w, !(codePoint < (codePoint = k <= bias ? 1 : bias + tMax <= k ? tMax : k - bias)); k += base) w > floor(maxInt / (codePoint = base - codePoint)) && error("overflow"), w *= codePoint;
                        bias = adapt(i - oldi, out = output.length + 1, 0 == oldi), floor(i / out) > maxInt - n && error("overflow"), n += floor(i / out), i %= out, output.splice(i++, 0, n)
                    }
                    return ucs2encode(output)
                }

                function encode(input) {
                    for (var delta, handledCPCount, basicLength, m, q, k, currentValue, handledCPCountPlusOne, t, qMinusT, output = [], inputLength = (input = ucs2decode(input)).length, n = 128, bias = 72, j = delta = 0; j < inputLength; ++j)(currentValue = input[j]) < 128 && output.push(stringFromCharCode(currentValue));
                    for (handledCPCount = basicLength = output.length, basicLength && output.push("-"); handledCPCount < inputLength;) {
                        for (m = maxInt, j = 0; j < inputLength; ++j) n <= (currentValue = input[j]) && currentValue < m && (m = currentValue);
                        for (m - n > floor((maxInt - delta) / (handledCPCountPlusOne = handledCPCount + 1)) && error("overflow"), delta += (m - n) * handledCPCountPlusOne, n = m, j = 0; j < inputLength; ++j)
                            if ((currentValue = input[j]) < n && ++delta > maxInt && error("overflow"), currentValue == n) {
                                for (q = delta, k = base; !(q < (t = k <= bias ? 1 : bias + tMax <= k ? tMax : k - bias)); k += base) output.push(stringFromCharCode(digitToBasic(t + (qMinusT = q - t) % (t = base - t), 0))), q = floor(qMinusT / t);
                                output.push(stringFromCharCode(digitToBasic(q, 0))), bias = adapt(delta, handledCPCountPlusOne, handledCPCount == basicLength), delta = 0, ++handledCPCount
                            }++ delta, ++n
                    }
                    return output.join("")
                }
                if (punycode = {
                        version: "1.4.1",
                        ucs2: {
                            decode: ucs2decode,
                            encode: ucs2encode
                        },
                        decode: decode,
                        encode: encode,
                        toASCII: function(input) {
                            return mapDomain(input, function(string) {
                                return regexNonASCII.test(string) ? "xn--" + encode(string) : string
                            })
                        },
                        toUnicode: function(input) {
                            return mapDomain(input, function(string) {
                                return regexPunycode.test(string) ? decode(string.slice(4).toLowerCase()) : string
                            })
                        }
                    }, "function" == typeof define && "object" == typeof define.amd && define.amd) define("punycode", function() {
                    return punycode
                });
                else if (freeExports && freeModule)
                    if (module.exports == freeExports) freeModule.exports = punycode;
                    else
                        for (key in punycode) punycode.hasOwnProperty(key) && (freeExports[key] = punycode[key]);
                else root.punycode = punycode
            }.call(this)
        }.call(this, "undefined" != typeof global ? global : "undefined" != typeof self ? self : "undefined" != typeof window ? window : {})
    }, {}],
    11: [function(require, module, exports) {
        "use strict";
        module.exports = function(qs, sep, eq, options) {
            sep = sep || "&", eq = eq || "=";
            var obj = {};
            if ("string" == typeof qs && 0 !== qs.length) {
                var regexp = /\+/g,
                    sep = (qs = qs.split(sep), 1e3),
                    len = (options && "number" == typeof options.maxKeys && (sep = options.maxKeys), qs.length);
                0 < sep && sep < len && (len = sep);
                for (var i = 0; i < len; ++i) {
                    var kstr, x = qs[i].replace(regexp, "%20"),
                        idx = x.indexOf(eq),
                        idx = 0 <= idx ? (kstr = x.substr(0, idx), x.substr(idx + 1)) : (kstr = x, ""),
                        x = decodeURIComponent(kstr),
                        idx = decodeURIComponent(idx);
                    ! function(obj, prop) {
                        return Object.prototype.hasOwnProperty.call(obj, prop)
                    }(obj, x) ? obj[x] = idx: isArray(obj[x]) ? obj[x].push(idx) : obj[x] = [obj[x], idx]
                }
            }
            return obj
        };
        var isArray = Array.isArray || function(xs) {
            return "[object Array]" === Object.prototype.toString.call(xs)
        }
    }, {}],
    12: [function(require, module, exports) {
        "use strict";

        function stringifyPrimitive(v) {
            switch (typeof v) {
                case "string":
                    return v;
                case "boolean":
                    return v ? "true" : "false";
                case "number":
                    return isFinite(v) ? v : "";
                default:
                    return ""
            }
        }
        module.exports = function(obj, sep, eq, name) {
            return sep = sep || "&", eq = eq || "=", "object" == typeof(obj = null === obj ? void 0 : obj) ? map(objectKeys(obj), function(k) {
                var ks = encodeURIComponent(stringifyPrimitive(k)) + eq;
                return isArray(obj[k]) ? map(obj[k], function(v) {
                    return ks + encodeURIComponent(stringifyPrimitive(v))
                }).join(sep) : ks + encodeURIComponent(stringifyPrimitive(obj[k]))
            }).join(sep) : name ? encodeURIComponent(stringifyPrimitive(name)) + eq + encodeURIComponent(stringifyPrimitive(obj)) : ""
        };
        var isArray = Array.isArray || function(xs) {
            return "[object Array]" === Object.prototype.toString.call(xs)
        };

        function map(xs, f) {
            if (xs.map) return xs.map(f);
            for (var res = [], i = 0; i < xs.length; i++) res.push(f(xs[i], i));
            return res
        }
        var objectKeys = Object.keys || function(obj) {
            var key, res = [];
            for (key in obj) Object.prototype.hasOwnProperty.call(obj, key) && res.push(key);
            return res
        }
    }, {}],
    13: [function(require, module, exports) {
        "use strict";
        exports.decode = exports.parse = require("./decode"), exports.encode = exports.stringify = require("./encode")
    }, {
        "./decode": 11,
        "./encode": 12
    }],
    14: [function(require, module, exports) {
        var buffer = require("buffer"),
            Buffer = buffer.Buffer;

        function copyProps(src, dst) {
            for (var key in src) dst[key] = src[key]
        }

        function SafeBuffer(arg, encodingOrOffset, length) {
            return Buffer(arg, encodingOrOffset, length)
        }
        Buffer.from && Buffer.alloc && Buffer.allocUnsafe && Buffer.allocUnsafeSlow ? module.exports = buffer : (copyProps(buffer, exports), exports.Buffer = SafeBuffer), SafeBuffer.prototype = Object.create(Buffer.prototype), copyProps(Buffer, SafeBuffer), SafeBuffer.from = function(arg, encodingOrOffset, length) {
            if ("number" == typeof arg) throw new TypeError("Argument must not be a number");
            return Buffer(arg, encodingOrOffset, length)
        }, SafeBuffer.alloc = function(size, fill, encoding) {
            if ("number" != typeof size) throw new TypeError("Argument must be a number");
            size = Buffer(size);
            return void 0 !== fill ? "string" == typeof encoding ? size.fill(fill, encoding) : size.fill(fill) : size.fill(0), size
        }, SafeBuffer.allocUnsafe = function(size) {
            if ("number" != typeof size) throw new TypeError("Argument must be a number");
            return Buffer(size)
        }, SafeBuffer.allocUnsafeSlow = function(size) {
            if ("number" != typeof size) throw new TypeError("Argument must be a number");
            return buffer.SlowBuffer(size)
        }
    }, {
        buffer: 3
    }],
    15: [function(require, module, exports) {
        module.exports = Stream;
        var EE = require("events").EventEmitter;

        function Stream() {
            EE.call(this)
        }
        require("inherits")(Stream, EE), Stream.Readable = require("readable-stream/lib/_stream_readable.js"), Stream.Writable = require("readable-stream/lib/_stream_writable.js"), Stream.Duplex = require("readable-stream/lib/_stream_duplex.js"), Stream.Transform = require("readable-stream/lib/_stream_transform.js"), Stream.PassThrough = require("readable-stream/lib/_stream_passthrough.js"), Stream.finished = require("readable-stream/lib/internal/streams/end-of-stream.js"), Stream.pipeline = require("readable-stream/lib/internal/streams/pipeline.js"), (Stream.Stream = Stream).prototype.pipe = function(dest, options) {
            var source = this;

            function ondata(chunk) {
                dest.writable && !1 === dest.write(chunk) && source.pause && source.pause()
            }

            function ondrain() {
                source.readable && source.resume && source.resume()
            }
            source.on("data", ondata), dest.on("drain", ondrain), dest._isStdio || options && !1 === options.end || (source.on("end", onend), source.on("close", onclose));
            var didOnEnd = !1;

            function onend() {
                didOnEnd || (didOnEnd = !0, dest.end())
            }

            function onclose() {
                didOnEnd || (didOnEnd = !0, "function" == typeof dest.destroy && dest.destroy())
            }

            function onerror(er) {
                if (cleanup(), 0 === EE.listenerCount(this, "error")) throw er
            }

            function cleanup() {
                source.removeListener("data", ondata), dest.removeListener("drain", ondrain), source.removeListener("end", onend), source.removeListener("close", onclose), source.removeListener("error", onerror), dest.removeListener("error", onerror), source.removeListener("end", cleanup), source.removeListener("close", cleanup), dest.removeListener("close", cleanup)
            }
            return source.on("error", onerror), dest.on("error", onerror), source.on("end", cleanup), source.on("close", cleanup), dest.on("close", cleanup), dest.emit("pipe", source), dest
        }
    }, {
        events: 5,
        inherits: 8,
        "readable-stream/lib/_stream_duplex.js": 17,
        "readable-stream/lib/_stream_passthrough.js": 18,
        "readable-stream/lib/_stream_readable.js": 19,
        "readable-stream/lib/_stream_transform.js": 20,
        "readable-stream/lib/_stream_writable.js": 21,
        "readable-stream/lib/internal/streams/end-of-stream.js": 25,
        "readable-stream/lib/internal/streams/pipeline.js": 27
    }],
    16: [function(require, module, exports) {
        "use strict";
        var codes = {};

        function createErrorType(code, message, Base) {
            var NodeError = function(_Base) {
                var subClass, superClass;

                function NodeError(arg1, arg2, arg3) {
                    return _Base.call(this, function(arg1, arg2, arg3) {
                        return "string" == typeof message ? message : message(arg1, arg2, arg3)
                    }(arg1, arg2, arg3)) || this
                }
                return superClass = _Base, (subClass = NodeError).prototype = Object.create(superClass.prototype), (subClass.prototype.constructor = subClass).__proto__ = superClass, NodeError
            }(Base = Base || Error);
            NodeError.prototype.name = Base.name, NodeError.prototype.code = code, codes[code] = NodeError
        }

        function oneOf(expected, thing) {
            var len;
            return Array.isArray(expected) ? (len = expected.length, expected = expected.map(function(i) {
                return String(i)
            }), 2 < len ? "one of ".concat(thing, " ").concat(expected.slice(0, len - 1).join(", "), ", or ") + expected[len - 1] : 2 === len ? "one of ".concat(thing, " ").concat(expected[0], " or ").concat(expected[1]) : "of ".concat(thing, " ").concat(expected[0])) : "of ".concat(thing, " ").concat(String(expected))
        }
        createErrorType("ERR_INVALID_OPT_VALUE", function(name, value) {
            return 'The value "' + value + '" is invalid for option "' + name + '"'
        }, TypeError), createErrorType("ERR_INVALID_ARG_TYPE", function(name, expected, actual) {
            var determiner, pos, search;
            return "string" == typeof expected && (search = "not ", expected.substr(!pos || pos < 0 ? 0 : +pos, search.length) === search) ? (determiner = "must not be", expected = expected.replace(/^not /, "")) : determiner = "must be", search = (function(str, search, this_len) {
                return (void 0 === this_len || this_len > str.length) && (this_len = str.length), str.substring(this_len - search.length, this_len) === search
            }(name, " argument") ? "The ".concat(name, " ") : (pos = function(str, search, start) {
                return !((start = "number" != typeof start ? 0 : start) + search.length > str.length) && -1 !== str.indexOf(search, start)
            }(name, ".") ? "property" : "argument", 'The "'.concat(name, '" ').concat(pos, " "))).concat(determiner, " ").concat(oneOf(expected, "type")), search += ". Received type ".concat(typeof actual)
        }, TypeError), createErrorType("ERR_STREAM_PUSH_AFTER_EOF", "stream.push() after EOF"), createErrorType("ERR_METHOD_NOT_IMPLEMENTED", function(name) {
            return "The " + name + " method is not implemented"
        }), createErrorType("ERR_STREAM_PREMATURE_CLOSE", "Premature close"), createErrorType("ERR_STREAM_DESTROYED", function(name) {
            return "Cannot call " + name + " after a stream was destroyed"
        }), createErrorType("ERR_MULTIPLE_CALLBACK", "Callback called multiple times"), createErrorType("ERR_STREAM_CANNOT_PIPE", "Cannot pipe, not readable"), createErrorType("ERR_STREAM_WRITE_AFTER_END", "write after end"), createErrorType("ERR_STREAM_NULL_VALUES", "May not write null values to stream", TypeError), createErrorType("ERR_UNKNOWN_ENCODING", function(arg) {
            return "Unknown encoding: " + arg
        }, TypeError), createErrorType("ERR_STREAM_UNSHIFT_AFTER_END_EVENT", "stream.unshift() after end event"), module.exports.codes = codes
    }, {}],
    17: [function(require, module, exports) {
        ! function(process) {
            ! function() {
                "use strict";
                var objectKeys = Object.keys || function(obj) {
                    var key, keys = [];
                    for (key in obj) keys.push(key);
                    return keys
                };
                module.exports = Duplex;
                const Readable = require("./_stream_readable"),
                    Writable = require("./_stream_writable");
                require("inherits")(Duplex, Readable);
                for (var keys = objectKeys(Writable.prototype), v = 0; v < keys.length; v++) {
                    var method = keys[v];
                    Duplex.prototype[method] || (Duplex.prototype[method] = Writable.prototype[method])
                }

                function Duplex(options) {
                    if (!(this instanceof Duplex)) return new Duplex(options);
                    Readable.call(this, options), Writable.call(this, options), this.allowHalfOpen = !0, options && (!1 === options.readable && (this.readable = !1), !1 === options.writable && (this.writable = !1), !1 === options.allowHalfOpen) && (this.allowHalfOpen = !1, this.once("end", onend))
                }

                function onend() {
                    this._writableState.ended || process.nextTick(onEndNT, this)
                }

                function onEndNT(self) {
                    self.end()
                }
                Object.defineProperty(Duplex.prototype, "writableHighWaterMark", {
                    enumerable: !1,
                    get() {
                        return this._writableState.highWaterMark
                    }
                }), Object.defineProperty(Duplex.prototype, "writableBuffer", {
                    enumerable: !1,
                    get: function() {
                        return this._writableState && this._writableState.getBuffer()
                    }
                }), Object.defineProperty(Duplex.prototype, "writableLength", {
                    enumerable: !1,
                    get() {
                        return this._writableState.length
                    }
                }), Object.defineProperty(Duplex.prototype, "destroyed", {
                    enumerable: !1,
                    get() {
                        return void 0 !== this._readableState && void 0 !== this._writableState && this._readableState.destroyed && this._writableState.destroyed
                    },
                    set(value) {
                        void 0 !== this._readableState && void 0 !== this._writableState && (this._readableState.destroyed = value, this._writableState.destroyed = value)
                    }
                })
            }.call(this)
        }.call(this, require("_process"))
    }, {
        "./_stream_readable": 19,
        "./_stream_writable": 21,
        _process: 9,
        inherits: 8
    }],
    18: [function(require, module, exports) {
        "use strict";
        module.exports = PassThrough;
        const Transform = require("./_stream_transform");

        function PassThrough(options) {
            if (!(this instanceof PassThrough)) return new PassThrough(options);
            Transform.call(this, options)
        }
        require("inherits")(PassThrough, Transform), PassThrough.prototype._transform = function(chunk, encoding, cb) {
            cb(null, chunk)
        }
    }, {
        "./_stream_transform": 20,
        inherits: 8
    }],
    19: [function(require, module, exports) {
        ! function(process, global) {
            ! function() {
                "use strict";

                function EElistenerCount(emitter, type) {
                    return emitter.listeners(type).length
                }(module.exports = Readable).ReadableState = ReadableState, require("events").EventEmitter;
                var Duplex, Stream = require("./internal/streams/stream");
                const Buffer = require("buffer").Buffer,
                    OurUint8Array = (void 0 !== global ? global : "undefined" != typeof window ? window : "undefined" != typeof self ? self : {}).Uint8Array || function() {};
                var debugUtil = require("util");
                let debug;
                debug = debugUtil && debugUtil.debuglog ? debugUtil.debuglog("stream") : function() {};
                const BufferList = require("./internal/streams/buffer_list");
                debugUtil = require("./internal/streams/destroy");
                const _require = require("./internal/streams/state"),
                    getHighWaterMark = _require.getHighWaterMark,
                    _require$codes = require("../errors").codes,
                    ERR_INVALID_ARG_TYPE = _require$codes.ERR_INVALID_ARG_TYPE,
                    ERR_STREAM_PUSH_AFTER_EOF = _require$codes.ERR_STREAM_PUSH_AFTER_EOF,
                    ERR_METHOD_NOT_IMPLEMENTED = _require$codes.ERR_METHOD_NOT_IMPLEMENTED,
                    ERR_STREAM_UNSHIFT_AFTER_END_EVENT = _require$codes.ERR_STREAM_UNSHIFT_AFTER_END_EVENT;
                let StringDecoder, createReadableStreamAsyncIterator, from;
                require("inherits")(Readable, Stream);
                const errorOrDestroy = debugUtil.errorOrDestroy,
                    kProxyEvents = ["error", "close", "destroy", "pause", "resume"];

                function ReadableState(options, stream, isDuplex) {
                    Duplex = Duplex || require("./_stream_duplex"), options = options || {}, "boolean" != typeof isDuplex && (isDuplex = stream instanceof Duplex), this.objectMode = !!options.objectMode, isDuplex && (this.objectMode = this.objectMode || !!options.readableObjectMode), this.highWaterMark = getHighWaterMark(this, options, "readableHighWaterMark", isDuplex), this.buffer = new BufferList, this.length = 0, this.pipes = null, this.pipesCount = 0, this.flowing = null, this.ended = !1, this.endEmitted = !1, this.reading = !1, this.sync = !0, this.needReadable = !1, this.emittedReadable = !1, this.readableListening = !1, this.resumeScheduled = !1, this.paused = !0, this.emitClose = !1 !== options.emitClose, this.autoDestroy = !!options.autoDestroy, this.destroyed = !1, this.defaultEncoding = options.defaultEncoding || "utf8", this.awaitDrain = 0, this.readingMore = !1, this.decoder = null, this.encoding = null, options.encoding && (StringDecoder = StringDecoder || require("string_decoder/").StringDecoder, this.decoder = new StringDecoder(options.encoding), this.encoding = options.encoding)
                }

                function Readable(options) {
                    if (Duplex = Duplex || require("./_stream_duplex"), !(this instanceof Readable)) return new Readable(options);
                    var isDuplex = this instanceof Duplex;
                    this._readableState = new ReadableState(options, this, isDuplex), this.readable = !0, options && ("function" == typeof options.read && (this._read = options.read), "function" == typeof options.destroy) && (this._destroy = options.destroy), Stream.call(this)
                }

                function readableAddChunk(stream, chunk, encoding, addToFront, skipChunkCheck) {
                    debug("readableAddChunk", chunk);
                    var er, state = stream._readableState;
                    if (null === chunk) state.reading = !1, ! function(stream, state) {
                        var chunk;
                        debug("onEofChunk"), state.ended || (state.decoder && (chunk = state.decoder.end()) && chunk.length && (state.buffer.push(chunk), state.length += state.objectMode ? 1 : chunk.length), state.ended = !0, state.sync ? emitReadable(stream) : (state.needReadable = !1, state.emittedReadable || (state.emittedReadable = !0, emitReadable_(stream))))
                    }(stream, state);
                    else if (er = skipChunkCheck ? er : function(state, chunk) {
                            var er;
                            ! function(obj) {
                                return Buffer.isBuffer(obj) || obj instanceof OurUint8Array
                            }(chunk) && "string" != typeof chunk && void 0 !== chunk && !state.objectMode && (er = new ERR_INVALID_ARG_TYPE("chunk", ["string", "Buffer", "Uint8Array"], chunk));
                            return er
                        }(state, chunk)) errorOrDestroy(stream, er);
                    else if (state.objectMode || chunk && 0 < chunk.length)
                        if ("string" == typeof chunk || state.objectMode || Object.getPrototypeOf(chunk) === Buffer.prototype || (chunk = function(chunk) {
                                return Buffer.from(chunk)
                            }(chunk)), addToFront) state.endEmitted ? errorOrDestroy(stream, new ERR_STREAM_UNSHIFT_AFTER_END_EVENT) : addChunk(stream, state, chunk, !0);
                        else if (state.ended) errorOrDestroy(stream, new ERR_STREAM_PUSH_AFTER_EOF);
                    else {
                        if (state.destroyed) return !1;
                        state.reading = !1, !state.decoder || encoding || (chunk = state.decoder.write(chunk), state.objectMode) || 0 !== chunk.length ? addChunk(stream, state, chunk, !1) : maybeReadMore(stream, state)
                    } else addToFront || (state.reading = !1, maybeReadMore(stream, state));
                    return !state.ended && (state.length < state.highWaterMark || 0 === state.length)
                }

                function addChunk(stream, state, chunk, addToFront) {
                    state.flowing && 0 === state.length && !state.sync ? (state.awaitDrain = 0, stream.emit("data", chunk)) : (state.length += state.objectMode ? 1 : chunk.length, addToFront ? state.buffer.unshift(chunk) : state.buffer.push(chunk), state.needReadable && emitReadable(stream)), maybeReadMore(stream, state)
                }
                Object.defineProperty(Readable.prototype, "destroyed", {
                    enumerable: !1,
                    get() {
                        return void 0 !== this._readableState && this._readableState.destroyed
                    },
                    set(value) {
                        this._readableState && (this._readableState.destroyed = value)
                    }
                }), Readable.prototype.destroy = debugUtil.destroy, Readable.prototype._undestroy = debugUtil.undestroy, Readable.prototype._destroy = function(err, cb) {
                    cb(err)
                }, Readable.prototype.push = function(chunk, encoding) {
                    var skipChunkCheck, state = this._readableState;
                    return state.objectMode ? skipChunkCheck = !0 : "string" == typeof chunk && ((encoding = encoding || state.defaultEncoding) !== state.encoding && (chunk = Buffer.from(chunk, encoding), encoding = ""), skipChunkCheck = !0), readableAddChunk(this, chunk, encoding, !1, skipChunkCheck)
                }, Readable.prototype.unshift = function(chunk) {
                    return readableAddChunk(this, chunk, null, !0, !1)
                }, Readable.prototype.isPaused = function() {
                    return !1 === this._readableState.flowing
                }, Readable.prototype.setEncoding = function(enc) {
                    var decoder = new(StringDecoder = StringDecoder || require("string_decoder/").StringDecoder)(enc);
                    this._readableState.decoder = decoder, this._readableState.encoding = this._readableState.decoder.encoding;
                    let p = this._readableState.buffer.head,
                        content = "";
                    for (; null !== p;) content += decoder.write(p.data), p = p.next;
                    return this._readableState.buffer.clear(), "" !== content && this._readableState.buffer.push(content), this._readableState.length = content.length, this
                };
                const MAX_HWM = 1073741824;

                function howMuchToRead(n, state) {
                    return n <= 0 || 0 === state.length && state.ended ? 0 : state.objectMode ? 1 : n != n ? (state.flowing && state.length ? state.buffer.head.data : state).length : (n > state.highWaterMark && (state.highWaterMark = function(n) {
                        return n >= MAX_HWM ? n = MAX_HWM : (n--, n = (n = (n = (n = (n |= n >>> 1) | n >>> 2) | n >>> 4) | n >>> 8) | n >>> 16, n++), n
                    }(n)), n <= state.length ? n : state.ended ? state.length : (state.needReadable = !0, 0))
                }

                function emitReadable(stream) {
                    var state = stream._readableState;
                    debug("emitReadable", state.needReadable, state.emittedReadable), state.needReadable = !1, state.emittedReadable || (debug("emitReadable", state.flowing), state.emittedReadable = !0, process.nextTick(emitReadable_, stream))
                }

                function emitReadable_(stream) {
                    var state = stream._readableState;
                    debug("emitReadable_", state.destroyed, state.length, state.ended), state.destroyed || !state.length && !state.ended || (stream.emit("readable"), state.emittedReadable = !1), state.needReadable = !state.flowing && !state.ended && state.length <= state.highWaterMark, flow(stream)
                }

                function maybeReadMore(stream, state) {
                    state.readingMore || (state.readingMore = !0, process.nextTick(maybeReadMore_, stream, state))
                }

                function maybeReadMore_(stream, state) {
                    for (; !state.reading && !state.ended && (state.length < state.highWaterMark || state.flowing && 0 === state.length);) {
                        var len = state.length;
                        if (debug("maybeReadMore read 0"), stream.read(0), len === state.length) break
                    }
                    state.readingMore = !1
                }

                function updateReadableListening(self) {
                    var state = self._readableState;
                    state.readableListening = 0 < self.listenerCount("readable"), state.resumeScheduled && !state.paused ? state.flowing = !0 : 0 < self.listenerCount("data") && self.resume()
                }

                function nReadingNextTick(self) {
                    debug("readable nexttick read 0"), self.read(0)
                }

                function resume_(stream, state) {
                    debug("resume", state.reading), state.reading || stream.read(0), state.resumeScheduled = !1, stream.emit("resume"), flow(stream), state.flowing && !state.reading && stream.read(0)
                }

                function flow(stream) {
                    var state = stream._readableState;
                    for (debug("flow", state.flowing); state.flowing && null !== stream.read(););
                }

                function fromList(n, state) {
                    var ret;
                    return 0 === state.length ? null : (state.objectMode ? ret = state.buffer.shift() : !n || n >= state.length ? (ret = state.decoder ? state.buffer.join("") : 1 === state.buffer.length ? state.buffer.first() : state.buffer.concat(state.length), state.buffer.clear()) : ret = state.buffer.consume(n, state.decoder), ret)
                }

                function endReadable(stream) {
                    var state = stream._readableState;
                    debug("endReadable", state.endEmitted), state.endEmitted || (state.ended = !0, process.nextTick(endReadableNT, state, stream))
                }

                function endReadableNT(state, stream) {
                    debug("endReadableNT", state.endEmitted, state.length), state.endEmitted || 0 !== state.length || (state.endEmitted = !0, stream.readable = !1, stream.emit("end"), state.autoDestroy && (!(state = stream._writableState) || state.autoDestroy && state.finished) && stream.destroy())
                }

                function indexOf(xs, x) {
                    for (var i = 0, l = xs.length; i < l; i++)
                        if (xs[i] === x) return i;
                    return -1
                }
                Readable.prototype.read = function(n) {
                    debug("read", n), n = parseInt(n, 10);
                    var doRead, state = this._readableState,
                        nOrig = n;
                    return 0 !== n && (state.emittedReadable = !1), 0 === n && state.needReadable && ((0 !== state.highWaterMark ? state.length >= state.highWaterMark : 0 < state.length) || state.ended) ? (debug("read: emitReadable", state.length, state.ended), (0 === state.length && state.ended ? endReadable : emitReadable)(this), null) : 0 === (n = howMuchToRead(n, state)) && state.ended ? (0 === state.length && endReadable(this), null) : (doRead = state.needReadable, debug("need readable", doRead), (0 === state.length || state.length - n < state.highWaterMark) && (doRead = !0, debug("length less than watermark", doRead)), state.ended || state.reading ? (doRead = !1, debug("reading or ended", doRead)) : doRead && (debug("do read"), state.reading = !0, state.sync = !0, 0 === state.length && (state.needReadable = !0), this._read(state.highWaterMark), state.sync = !1, state.reading || (n = howMuchToRead(nOrig, state))), null === (doRead = 0 < n ? fromList(n, state) : null) ? (state.needReadable = state.length <= state.highWaterMark, n = 0) : (state.length -= n, state.awaitDrain = 0), 0 === state.length && (state.ended || (state.needReadable = !0), nOrig !== n) && state.ended && endReadable(this), null !== doRead && this.emit("data", doRead), doRead)
                }, Readable.prototype._read = function(n) {
                    errorOrDestroy(this, new ERR_METHOD_NOT_IMPLEMENTED("_read()"))
                }, Readable.prototype.pipe = function(dest, pipeOpts) {
                    var src = this,
                        state = this._readableState;
                    switch (state.pipesCount) {
                        case 0:
                            state.pipes = dest;
                            break;
                        case 1:
                            state.pipes = [state.pipes, dest];
                            break;
                        default:
                            state.pipes.push(dest)
                    }
                    state.pipesCount += 1, debug("pipe count=%d opts=%j", state.pipesCount, pipeOpts);
                    pipeOpts = (!pipeOpts || !1 !== pipeOpts.end) && dest !== process.stdout && dest !== process.stderr ? onend : unpipe;

                    function onunpipe(readable, unpipeInfo) {
                        debug("onunpipe"), readable === src && unpipeInfo && !1 === unpipeInfo.hasUnpiped && (unpipeInfo.hasUnpiped = !0, debug("cleanup"), dest.removeListener("close", onclose), dest.removeListener("finish", onfinish), dest.removeListener("drain", ondrain), dest.removeListener("error", onerror), dest.removeListener("unpipe", onunpipe), src.removeListener("end", onend), src.removeListener("end", unpipe), src.removeListener("data", ondata), cleanedUp = !0, !state.awaitDrain || dest._writableState && !dest._writableState.needDrain || ondrain())
                    }

                    function onend() {
                        debug("onend"), dest.end()
                    }
                    state.endEmitted ? process.nextTick(pipeOpts) : src.once("end", pipeOpts), dest.on("unpipe", onunpipe);
                    var ondrain = function(src) {
                            return function() {
                                var state = src._readableState;
                                debug("pipeOnDrain", state.awaitDrain), state.awaitDrain && state.awaitDrain--, 0 === state.awaitDrain && EElistenerCount(src, "data") && (state.flowing = !0, flow(src))
                            }
                        }(src),
                        cleanedUp = (dest.on("drain", ondrain), !1);

                    function ondata(chunk) {
                        debug("ondata");
                        chunk = dest.write(chunk);
                        debug("dest.write", chunk), !1 === chunk && ((1 === state.pipesCount && state.pipes === dest || 1 < state.pipesCount && -1 !== indexOf(state.pipes, dest)) && !cleanedUp && (debug("false write response, pause", state.awaitDrain), state.awaitDrain++), src.pause())
                    }

                    function onerror(er) {
                        debug("onerror", er), unpipe(), dest.removeListener("error", onerror), 0 === EElistenerCount(dest, "error") && errorOrDestroy(dest, er)
                    }

                    function onclose() {
                        dest.removeListener("finish", onfinish), unpipe()
                    }

                    function onfinish() {
                        debug("onfinish"), dest.removeListener("close", onclose), unpipe()
                    }

                    function unpipe() {
                        debug("unpipe"), src.unpipe(dest)
                    }
                    return src.on("data", ondata),
                        function(emitter, event, fn) {
                            if ("function" == typeof emitter.prependListener) return emitter.prependListener(event, fn);
                            emitter._events && emitter._events[event] ? Array.isArray(emitter._events[event]) ? emitter._events[event].unshift(fn) : emitter._events[event] = [fn, emitter._events[event]] : emitter.on(event, fn)
                        }(dest, "error", onerror), dest.once("close", onclose), dest.once("finish", onfinish), dest.emit("pipe", src), state.flowing || (debug("pipe resume"), src.resume()), dest
                }, Readable.prototype.unpipe = function(dest) {
                    var state = this._readableState,
                        unpipeInfo = {
                            hasUnpiped: !1
                        };
                    if (0 !== state.pipesCount)
                        if (1 === state.pipesCount) dest && dest !== state.pipes || (dest = dest || state.pipes, state.pipes = null, state.pipesCount = 0, state.flowing = !1, dest && dest.emit("unpipe", this, unpipeInfo));
                        else if (dest) {
                        var index = indexOf(state.pipes, dest); - 1 !== index && (state.pipes.splice(index, 1), --state.pipesCount, 1 === state.pipesCount && (state.pipes = state.pipes[0]), dest.emit("unpipe", this, unpipeInfo))
                    } else {
                        var dests = state.pipes,
                            len = state.pipesCount;
                        state.pipes = null, state.pipesCount = 0, state.flowing = !1;
                        for (var i = 0; i < len; i++) dests[i].emit("unpipe", this, {
                            hasUnpiped: !1
                        })
                    }
                    return this
                }, Readable.prototype.addListener = Readable.prototype.on = function(ev, fn) {
                    var fn = Stream.prototype.on.call(this, ev, fn),
                        state = this._readableState;
                    return "data" === ev ? (state.readableListening = 0 < this.listenerCount("readable"), !1 !== state.flowing && this.resume()) : "readable" !== ev || state.endEmitted || state.readableListening || (state.readableListening = state.needReadable = !0, state.flowing = !1, state.emittedReadable = !1, debug("on readable", state.length, state.reading), state.length ? emitReadable(this) : state.reading || process.nextTick(nReadingNextTick, this)), fn
                }, Readable.prototype.removeListener = function(ev, fn) {
                    fn = Stream.prototype.removeListener.call(this, ev, fn);
                    return "readable" === ev && process.nextTick(updateReadableListening, this), fn
                }, Readable.prototype.removeAllListeners = function(ev) {
                    var res = Stream.prototype.removeAllListeners.apply(this, arguments);
                    return "readable" !== ev && void 0 !== ev || process.nextTick(updateReadableListening, this), res
                }, Readable.prototype.resume = function() {
                    var state = this._readableState;
                    return state.flowing || (debug("resume"), state.flowing = !state.readableListening, function(stream, state) {
                        state.resumeScheduled || (state.resumeScheduled = !0, process.nextTick(resume_, stream, state))
                    }(this, state)), state.paused = !1, this
                }, Readable.prototype.pause = function() {
                    return debug("call pause flowing=%j", this._readableState.flowing), !1 !== this._readableState.flowing && (debug("pause"), this._readableState.flowing = !1, this.emit("pause")), this._readableState.paused = !0, this
                }, Readable.prototype.wrap = function(stream) {
                    var i, state = this._readableState,
                        paused = !1;
                    for (i in stream.on("end", () => {
                            var chunk;
                            debug("wrapped end"), state.decoder && !state.ended && (chunk = state.decoder.end()) && chunk.length && this.push(chunk), this.push(null)
                        }), stream.on("data", chunk => {
                            debug("wrapped data"), state.decoder && (chunk = state.decoder.write(chunk)), state.objectMode && null == chunk || (state.objectMode || chunk && chunk.length) && !this.push(chunk) && (paused = !0, stream.pause())
                        }), stream) void 0 === this[i] && "function" == typeof stream[i] && (this[i] = function(method) {
                        return function() {
                            return stream[method].apply(stream, arguments)
                        }
                    }(i));
                    for (var n = 0; n < kProxyEvents.length; n++) stream.on(kProxyEvents[n], this.emit.bind(this, kProxyEvents[n]));
                    return this._read = n => {
                        debug("wrapped _read", n), paused && (paused = !1, stream.resume())
                    }, this
                }, "function" == typeof Symbol && (Readable.prototype[Symbol.asyncIterator] = function() {
                    return (createReadableStreamAsyncIterator = void 0 === createReadableStreamAsyncIterator ? require("./internal/streams/async_iterator") : createReadableStreamAsyncIterator)(this)
                }), Object.defineProperty(Readable.prototype, "readableHighWaterMark", {
                    enumerable: !1,
                    get: function() {
                        return this._readableState.highWaterMark
                    }
                }), Object.defineProperty(Readable.prototype, "readableBuffer", {
                    enumerable: !1,
                    get: function() {
                        return this._readableState && this._readableState.buffer
                    }
                }), Object.defineProperty(Readable.prototype, "readableFlowing", {
                    enumerable: !1,
                    get: function() {
                        return this._readableState.flowing
                    },
                    set: function(state) {
                        this._readableState && (this._readableState.flowing = state)
                    }
                }), Readable._fromList = fromList, Object.defineProperty(Readable.prototype, "readableLength", {
                    enumerable: !1,
                    get() {
                        return this._readableState.length
                    }
                }), "function" == typeof Symbol && (Readable.from = function(iterable, opts) {
                    return (from = void 0 === from ? require("./internal/streams/from") : from)(Readable, iterable, opts)
                })
            }.call(this)
        }.call(this, require("_process"), "undefined" != typeof global ? global : "undefined" != typeof self ? self : "undefined" != typeof window ? window : {})
    }, {
        "../errors": 16,
        "./_stream_duplex": 17,
        "./internal/streams/async_iterator": 22,
        "./internal/streams/buffer_list": 23,
        "./internal/streams/destroy": 24,
        "./internal/streams/from": 26,
        "./internal/streams/state": 28,
        "./internal/streams/stream": 29,
        _process: 9,
        buffer: 3,
        events: 5,
        inherits: 8,
        "string_decoder/": 49,
        util: 2
    }],
    20: [function(require, module, exports) {
        "use strict";
        module.exports = Transform;
        const _require$codes = require("../errors").codes,
            ERR_METHOD_NOT_IMPLEMENTED = _require$codes.ERR_METHOD_NOT_IMPLEMENTED,
            ERR_MULTIPLE_CALLBACK = _require$codes.ERR_MULTIPLE_CALLBACK,
            ERR_TRANSFORM_ALREADY_TRANSFORMING = _require$codes.ERR_TRANSFORM_ALREADY_TRANSFORMING,
            ERR_TRANSFORM_WITH_LENGTH_0 = _require$codes.ERR_TRANSFORM_WITH_LENGTH_0,
            Duplex = require("./_stream_duplex");

        function Transform(options) {
            if (!(this instanceof Transform)) return new Transform(options);
            Duplex.call(this, options), this._transformState = {
                afterTransform: function(er, data) {
                    var ts = this._transformState,
                        cb = (ts.transforming = !1, ts.writecb);
                    if (null === cb) return this.emit("error", new ERR_MULTIPLE_CALLBACK);
                    ts.writechunk = null, (ts.writecb = null) != data && this.push(data), cb(er), (ts = this._readableState).reading = !1, (ts.needReadable || ts.length < ts.highWaterMark) && this._read(ts.highWaterMark)
                }.bind(this),
                needTransform: !1,
                transforming: !1,
                writecb: null,
                writechunk: null,
                writeencoding: null
            }, this._readableState.needReadable = !0, this._readableState.sync = !1, options && ("function" == typeof options.transform && (this._transform = options.transform), "function" == typeof options.flush) && (this._flush = options.flush), this.on("prefinish", prefinish)
        }

        function prefinish() {
            "function" != typeof this._flush || this._readableState.destroyed ? done(this, null, null) : this._flush((er, data) => {
                done(this, er, data)
            })
        }

        function done(stream, er, data) {
            if (er) return stream.emit("error", er);
            if (null != data && stream.push(data), stream._writableState.length) throw new ERR_TRANSFORM_WITH_LENGTH_0;
            if (stream._transformState.transforming) throw new ERR_TRANSFORM_ALREADY_TRANSFORMING;
            stream.push(null)
        }
        require("inherits")(Transform, Duplex), Transform.prototype.push = function(chunk, encoding) {
            return this._transformState.needTransform = !1, Duplex.prototype.push.call(this, chunk, encoding)
        }, Transform.prototype._transform = function(chunk, encoding, cb) {
            cb(new ERR_METHOD_NOT_IMPLEMENTED("_transform()"))
        }, Transform.prototype._write = function(chunk, encoding, cb) {
            var ts = this._transformState;
            ts.writecb = cb, ts.writechunk = chunk, ts.writeencoding = encoding, !ts.transforming && (cb = this._readableState, ts.needTransform || cb.needReadable || cb.length < cb.highWaterMark) && this._read(cb.highWaterMark)
        }, Transform.prototype._read = function(n) {
            var ts = this._transformState;
            null === ts.writechunk || ts.transforming ? ts.needTransform = !0 : (ts.transforming = !0, this._transform(ts.writechunk, ts.writeencoding, ts.afterTransform))
        }, Transform.prototype._destroy = function(err, cb) {
            Duplex.prototype._destroy.call(this, err, err2 => {
                cb(err2)
            })
        }
    }, {
        "../errors": 16,
        "./_stream_duplex": 17,
        inherits: 8
    }],
    21: [function(require, module, exports) {
        ! function(process, global) {
            ! function() {
                "use strict";

                function CorkedRequest(state) {
                    this.next = null, this.entry = null, this.finish = () => {
                        ! function(corkReq, state, err) {
                            var entry = corkReq.entry;
                            corkReq.entry = null;
                            for (; entry;) {
                                var cb = entry.callback;
                                state.pendingcb--, cb(err), entry = entry.next
                            }
                            state.corkedRequestsFree.next = corkReq
                        }(this, state)
                    }
                }
                var Duplex;
                (module.exports = Writable).WritableState = WritableState;
                const internalUtil = {
                    deprecate: require("util-deprecate")
                };
                var Stream = require("./internal/streams/stream");
                const Buffer = require("buffer").Buffer,
                    OurUint8Array = (void 0 !== global ? global : "undefined" != typeof window ? window : "undefined" != typeof self ? self : {}).Uint8Array || function() {};
                var realHasInstance, destroyImpl = require("./internal/streams/destroy");
                const _require = require("./internal/streams/state"),
                    getHighWaterMark = _require.getHighWaterMark,
                    _require$codes = require("../errors").codes,
                    ERR_INVALID_ARG_TYPE = _require$codes.ERR_INVALID_ARG_TYPE,
                    ERR_METHOD_NOT_IMPLEMENTED = _require$codes.ERR_METHOD_NOT_IMPLEMENTED,
                    ERR_MULTIPLE_CALLBACK = _require$codes.ERR_MULTIPLE_CALLBACK,
                    ERR_STREAM_CANNOT_PIPE = _require$codes.ERR_STREAM_CANNOT_PIPE,
                    ERR_STREAM_DESTROYED = _require$codes.ERR_STREAM_DESTROYED,
                    ERR_STREAM_NULL_VALUES = _require$codes.ERR_STREAM_NULL_VALUES,
                    ERR_STREAM_WRITE_AFTER_END = _require$codes.ERR_STREAM_WRITE_AFTER_END,
                    ERR_UNKNOWN_ENCODING = _require$codes.ERR_UNKNOWN_ENCODING,
                    errorOrDestroy = destroyImpl.errorOrDestroy;

                function nop() {}

                function WritableState(options, stream, isDuplex) {
                    Duplex = Duplex || require("./_stream_duplex"), options = options || {}, "boolean" != typeof isDuplex && (isDuplex = stream instanceof Duplex), this.objectMode = !!options.objectMode, isDuplex && (this.objectMode = this.objectMode || !!options.writableObjectMode), this.highWaterMark = getHighWaterMark(this, options, "writableHighWaterMark", isDuplex), this.finalCalled = !1, this.needDrain = !1, this.ending = !1, this.ended = !1, this.finished = !1;
                    isDuplex = (this.destroyed = !1) === options.decodeStrings;
                    this.decodeStrings = !isDuplex, this.defaultEncoding = options.defaultEncoding || "utf8", this.length = 0, this.writing = !1, this.corked = 0, this.sync = !0, this.bufferProcessing = !1, this.onwrite = function(er) {
                        ! function(stream, er) {
                            var state = stream._writableState,
                                sync = state.sync,
                                cb = state.writecb;
                            if ("function" != typeof cb) throw new ERR_MULTIPLE_CALLBACK;
                            (function(state) {
                                state.writing = !1, state.writecb = null, state.length -= state.writelen, state.writelen = 0
                            })(state), er ? function(stream, state, sync, er, cb) {
                                --state.pendingcb, sync ? (process.nextTick(cb, er), process.nextTick(finishMaybe, stream, state), stream._writableState.errorEmitted = !0, errorOrDestroy(stream, er)) : (cb(er), stream._writableState.errorEmitted = !0, errorOrDestroy(stream, er), finishMaybe(stream, state))
                            }(stream, state, sync, er, cb) : ((er = needFinish(state) || stream.destroyed) || state.corked || state.bufferProcessing || !state.bufferedRequest || clearBuffer(stream, state), sync ? process.nextTick(afterWrite, stream, state, er, cb) : afterWrite(stream, state, er, cb))
                        }(stream, er)
                    }, this.writecb = null, this.writelen = 0, this.bufferedRequest = null, this.lastBufferedRequest = null, this.pendingcb = 0, this.prefinished = !1, this.errorEmitted = !1, this.emitClose = !1 !== options.emitClose, this.autoDestroy = !!options.autoDestroy, this.bufferedRequestCount = 0, this.corkedRequestsFree = new CorkedRequest(this)
                }
                require("inherits")(Writable, Stream), WritableState.prototype.getBuffer = function() {
                    for (var current = this.bufferedRequest, out = []; current;) out.push(current), current = current.next;
                    return out
                };
                try {
                    Object.defineProperty(WritableState.prototype, "buffer", {
                        get: internalUtil.deprecate(function() {
                            return this.getBuffer()
                        }, "_writableState.buffer is deprecated. Use _writableState.getBuffer instead.", "DEP0003")
                    })
                } catch (_) {}

                function Writable(options) {
                    var isDuplex = this instanceof(Duplex = Duplex || require("./_stream_duplex"));
                    if (!isDuplex && !realHasInstance.call(Writable, this)) return new Writable(options);
                    this._writableState = new WritableState(options, this, isDuplex), this.writable = !0, options && ("function" == typeof options.write && (this._write = options.write), "function" == typeof options.writev && (this._writev = options.writev), "function" == typeof options.destroy && (this._destroy = options.destroy), "function" == typeof options.final) && (this._final = options.final), Stream.call(this)
                }

                function doWrite(stream, state, writev, len, chunk, encoding, cb) {
                    state.writelen = len, state.writecb = cb, state.writing = !0, state.sync = !0, state.destroyed ? state.onwrite(new ERR_STREAM_DESTROYED("write")) : writev ? stream._writev(chunk, state.onwrite) : stream._write(chunk, encoding, state.onwrite), state.sync = !1
                }

                function afterWrite(stream, state, finished, cb) {
                    finished || ! function(stream, state) {
                        0 === state.length && state.needDrain && (state.needDrain = !1, stream.emit("drain"))
                    }(stream, state), state.pendingcb--, cb(), finishMaybe(stream, state)
                }

                function clearBuffer(stream, state) {
                    state.bufferProcessing = !0;
                    var entry = state.bufferedRequest;
                    if (stream._writev && entry && entry.next) {
                        for (var l = state.bufferedRequestCount, buffer = new Array(l), l = state.corkedRequestsFree, count = (l.entry = entry, 0), allBuffers = !0; entry;)(buffer[count] = entry).isBuf || (allBuffers = !1), entry = entry.next, count += 1;
                        buffer.allBuffers = allBuffers, doWrite(stream, state, !0, state.length, buffer, "", l.finish), state.pendingcb++, state.lastBufferedRequest = null, l.next ? (state.corkedRequestsFree = l.next, l.next = null) : state.corkedRequestsFree = new CorkedRequest(state), state.bufferedRequestCount = 0
                    } else {
                        for (; entry;) {
                            var chunk = entry.chunk,
                                encoding = entry.encoding,
                                cb = entry.callback;
                            if (doWrite(stream, state, !1, state.objectMode ? 1 : chunk.length, chunk, encoding, cb), entry = entry.next, state.bufferedRequestCount--, state.writing) break
                        }
                        null === entry && (state.lastBufferedRequest = null)
                    }
                    state.bufferedRequest = entry, state.bufferProcessing = !1
                }

                function needFinish(state) {
                    return state.ending && 0 === state.length && null === state.bufferedRequest && !state.finished && !state.writing
                }

                function callFinal(stream, state) {
                    stream._final(err => {
                        state.pendingcb--, err && errorOrDestroy(stream, err), state.prefinished = !0, stream.emit("prefinish"), finishMaybe(stream, state)
                    })
                }

                function finishMaybe(stream, state) {
                    var need = needFinish(state);
                    return need && (function(stream, state) {
                        state.prefinished || state.finalCalled || ("function" != typeof stream._final || state.destroyed ? (state.prefinished = !0, stream.emit("prefinish")) : (state.pendingcb++, state.finalCalled = !0, process.nextTick(callFinal, stream, state)))
                    }(stream, state), 0 === state.pendingcb) && (state.finished = !0, stream.emit("finish"), state.autoDestroy) && (!(state = stream._readableState) || state.autoDestroy && state.endEmitted) && stream.destroy(), need
                }
                "function" == typeof Symbol && Symbol.hasInstance && "function" == typeof Function.prototype[Symbol.hasInstance] ? (realHasInstance = Function.prototype[Symbol.hasInstance], Object.defineProperty(Writable, Symbol.hasInstance, {
                    value: function(object) {
                        return !!realHasInstance.call(this, object) || this === Writable && object && object._writableState instanceof WritableState
                    }
                })) : realHasInstance = function(object) {
                    return object instanceof this
                }, Writable.prototype.pipe = function() {
                    errorOrDestroy(this, new ERR_STREAM_CANNOT_PIPE)
                }, Writable.prototype.write = function(chunk, encoding, cb) {
                    var state = this._writableState,
                        ret = !1,
                        obj = !state.objectMode && (obj = chunk, Buffer.isBuffer(obj) || obj instanceof OurUint8Array);
                    return obj && !Buffer.isBuffer(chunk) && (chunk = function(chunk) {
                        return Buffer.from(chunk)
                    }(chunk)), "function" == typeof encoding && (cb = encoding, encoding = null), encoding = obj ? "buffer" : encoding || state.defaultEncoding, "function" != typeof cb && (cb = nop), state.ending ? function(stream, cb) {
                        var er = new ERR_STREAM_WRITE_AFTER_END;
                        errorOrDestroy(stream, er), process.nextTick(cb, er)
                    }(this, cb) : (obj || function(stream, state, chunk, cb) {
                        var er;
                        if (null === chunk ? er = new ERR_STREAM_NULL_VALUES : "string" == typeof chunk || state.objectMode || (er = new ERR_INVALID_ARG_TYPE("chunk", ["string", "Buffer"], chunk)), !er) return 1;
                        errorOrDestroy(stream, er), process.nextTick(cb, er)
                    }(this, state, chunk, cb)) && (state.pendingcb++, ret = function(stream, state, isBuf, chunk, encoding, cb) {
                        isBuf || (newChunk = function(state, chunk, encoding) {
                            state.objectMode || !1 === state.decodeStrings || "string" != typeof chunk || (chunk = Buffer.from(chunk, encoding));
                            return chunk
                        }(state, chunk, encoding), chunk !== newChunk && (isBuf = !0, encoding = "buffer", chunk = newChunk));
                        var newChunk = state.objectMode ? 1 : chunk.length,
                            ret = (state.length += newChunk, state.length < state.highWaterMark);
                        ret || (state.needDrain = !0); {
                            var last;
                            state.writing || state.corked ? (last = state.lastBufferedRequest, state.lastBufferedRequest = {
                                chunk: chunk,
                                encoding: encoding,
                                isBuf: isBuf,
                                callback: cb,
                                next: null
                            }, last ? last.next = state.lastBufferedRequest : state.bufferedRequest = state.lastBufferedRequest, state.bufferedRequestCount += 1) : doWrite(stream, state, !1, newChunk, chunk, encoding, cb)
                        }
                        return ret
                    }(this, state, obj, chunk, encoding, cb)), ret
                }, Writable.prototype.cork = function() {
                    this._writableState.corked++
                }, Writable.prototype.uncork = function() {
                    var state = this._writableState;
                    state.corked && (state.corked--, state.writing || state.corked || state.bufferProcessing || !state.bufferedRequest || clearBuffer(this, state))
                }, Writable.prototype.setDefaultEncoding = function(encoding) {
                    if ("string" == typeof encoding && (encoding = encoding.toLowerCase()), -1 < ["hex", "utf8", "utf-8", "ascii", "binary", "base64", "ucs2", "ucs-2", "utf16le", "utf-16le", "raw"].indexOf((encoding + "").toLowerCase())) return this._writableState.defaultEncoding = encoding, this;
                    throw new ERR_UNKNOWN_ENCODING(encoding)
                }, Object.defineProperty(Writable.prototype, "writableBuffer", {
                    enumerable: !1,
                    get: function() {
                        return this._writableState && this._writableState.getBuffer()
                    }
                }), Object.defineProperty(Writable.prototype, "writableHighWaterMark", {
                    enumerable: !1,
                    get: function() {
                        return this._writableState.highWaterMark
                    }
                }), Writable.prototype._write = function(chunk, encoding, cb) {
                    cb(new ERR_METHOD_NOT_IMPLEMENTED("_write()"))
                }, Writable.prototype._writev = null, Writable.prototype.end = function(chunk, encoding, cb) {
                    var state = this._writableState;
                    return "function" == typeof chunk ? (cb = chunk, encoding = chunk = null) : "function" == typeof encoding && (cb = encoding, encoding = null), null != chunk && this.write(chunk, encoding), state.corked && (state.corked = 1, this.uncork()), state.ending || function(stream, state, cb) {
                        state.ending = !0, finishMaybe(stream, state), cb && (state.finished ? process.nextTick(cb) : stream.once("finish", cb));
                        state.ended = !0, stream.writable = !1
                    }(this, state, cb), this
                }, Object.defineProperty(Writable.prototype, "writableLength", {
                    enumerable: !1,
                    get() {
                        return this._writableState.length
                    }
                }), Object.defineProperty(Writable.prototype, "destroyed", {
                    enumerable: !1,
                    get() {
                        return void 0 !== this._writableState && this._writableState.destroyed
                    },
                    set(value) {
                        this._writableState && (this._writableState.destroyed = value)
                    }
                }), Writable.prototype.destroy = destroyImpl.destroy, Writable.prototype._undestroy = destroyImpl.undestroy, Writable.prototype._destroy = function(err, cb) {
                    cb(err)
                }
            }.call(this)
        }.call(this, require("_process"), "undefined" != typeof global ? global : "undefined" != typeof self ? self : "undefined" != typeof window ? window : {})
    }, {
        "../errors": 16,
        "./_stream_duplex": 17,
        "./internal/streams/destroy": 24,
        "./internal/streams/state": 28,
        "./internal/streams/stream": 29,
        _process: 9,
        buffer: 3,
        inherits: 8,
        "util-deprecate": 53
    }],
    22: [function(require, module, exports) {
        ! function(process) {
            ! function() {
                "use strict";
                const finished = require("./end-of-stream"),
                    kLastResolve = Symbol("lastResolve"),
                    kLastReject = Symbol("lastReject"),
                    kError = Symbol("error"),
                    kEnded = Symbol("ended"),
                    kLastPromise = Symbol("lastPromise"),
                    kHandlePromise = Symbol("handlePromise"),
                    kStream = Symbol("stream");

                function readAndResolve(iter) {
                    var data, resolve = iter[kLastResolve];
                    null !== resolve && null !== (data = iter[kStream].read()) && (iter[kLastPromise] = null, iter[kLastResolve] = null, iter[kLastReject] = null, resolve({
                        value: data,
                        done: !1
                    }))
                }
                var AsyncIteratorPrototype = Object.getPrototypeOf(function() {});
                const ReadableStreamAsyncIteratorPrototype = Object.setPrototypeOf({
                    get stream() {
                        return this[kStream]
                    },
                    next() {
                        var error = this[kError];
                        if (null !== error) return Promise.reject(error);
                        if (this[kEnded]) return Promise.resolve({
                            value: void 0,
                            done: !0
                        });
                        if (this[kStream].destroyed) return new Promise((resolve, reject) => {
                            process.nextTick(() => {
                                this[kError] ? reject(this[kError]) : resolve({
                                    value: void 0,
                                    done: !0
                                })
                            })
                        });
                        error = this[kLastPromise];
                        let promise;
                        if (error) promise = new Promise(function(lastPromise, iter) {
                            return (resolve, reject) => {
                                lastPromise.then(() => {
                                    iter[kEnded] ? resolve({
                                        value: void 0,
                                        done: !0
                                    }) : iter[kHandlePromise](resolve, reject)
                                }, reject)
                            }
                        }(error, this));
                        else {
                            error = this[kStream].read();
                            if (null !== error) return Promise.resolve({
                                value: error,
                                done: !1
                            });
                            promise = new Promise(this[kHandlePromise])
                        }
                        return this[kLastPromise] = promise
                    },
                    [Symbol.asyncIterator]() {
                        return this
                    },
                    return () {
                        return new Promise((resolve, reject) => {
                            this[kStream].destroy(null, err => {
                                err ? reject(err) : resolve({
                                    value: void 0,
                                    done: !0
                                })
                            })
                        })
                    }
                }, AsyncIteratorPrototype);
                module.exports = stream => {
                    const iterator = Object.create(ReadableStreamAsyncIteratorPrototype, {
                        [kStream]: {
                            value: stream,
                            writable: !0
                        },
                        [kLastResolve]: {
                            value: null,
                            writable: !0
                        },
                        [kLastReject]: {
                            value: null,
                            writable: !0
                        },
                        [kError]: {
                            value: null,
                            writable: !0
                        },
                        [kEnded]: {
                            value: stream._readableState.endEmitted,
                            writable: !0
                        },
                        [kHandlePromise]: {
                            value: (resolve, reject) => {
                                var data = iterator[kStream].read();
                                data ? (iterator[kLastPromise] = null, iterator[kLastResolve] = null, iterator[kLastReject] = null, resolve({
                                    value: data,
                                    done: !1
                                })) : (iterator[kLastResolve] = resolve, iterator[kLastReject] = reject)
                            },
                            writable: !0
                        }
                    });
                    return iterator[kLastPromise] = null, finished(stream, err => {
                        var reject;
                        err && "ERR_STREAM_PREMATURE_CLOSE" !== err.code ? (null !== (reject = iterator[kLastReject]) && (iterator[kLastPromise] = null, iterator[kLastResolve] = null, iterator[kLastReject] = null, reject(err)), iterator[kError] = err) : (null !== (reject = iterator[kLastResolve]) && (iterator[kLastPromise] = null, iterator[kLastResolve] = null, reject({
                            value: void 0,
                            done: !(iterator[kLastReject] = null)
                        })), iterator[kEnded] = !0)
                    }), stream.on("readable", function(iter) {
                        process.nextTick(readAndResolve, iter)
                    }.bind(null, iterator)), iterator
                }
            }.call(this)
        }.call(this, require("_process"))
    }, {
        "./end-of-stream": 25,
        _process: 9
    }],
    23: [function(require, module, exports) {
        "use strict";

        function ownKeys(object, enumerableOnly) {
            var symbols, keys = Object.keys(object);
            return Object.getOwnPropertySymbols && (symbols = Object.getOwnPropertySymbols(object), enumerableOnly && (symbols = symbols.filter(function(sym) {
                return Object.getOwnPropertyDescriptor(object, sym).enumerable
            })), keys.push.apply(keys, symbols)), keys
        }

        function _objectSpread(target) {
            for (var i = 1; i < arguments.length; i++) {
                var source = null != arguments[i] ? arguments[i] : {};
                i % 2 ? ownKeys(Object(source), !0).forEach(function(key) {
                    ! function(obj, key, value) {
                        (key = function(arg) {
                            arg = function(input, hint) {
                                if ("object" != typeof input || null === input) return input;
                                var prim = input[Symbol.toPrimitive];
                                if (void 0 === prim) return ("string" === hint ? String : Number)(input);
                                prim = prim.call(input, hint || "default");
                                if ("object" != typeof prim) return prim;
                                throw new TypeError("@@toPrimitive must return a primitive value.")
                            }(arg, "string");
                            return "symbol" == typeof arg ? arg : String(arg)
                        }(key)) in obj ? Object.defineProperty(obj, key, {
                            value: value,
                            enumerable: !0,
                            configurable: !0,
                            writable: !0
                        }) : obj[key] = value
                    }(target, key, source[key])
                }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function(key) {
                    Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key))
                })
            }
            return target
        }
        const _require = require("buffer"),
            Buffer = _require.Buffer,
            _require2 = require("util"),
            inspect = _require2.inspect;
        require = inspect && inspect.custom || "inspect";
        module.exports = class {
            constructor() {
                this.head = null, this.tail = null, this.length = 0
            }
            push(v) {
                v = {
                    data: v,
                    next: null
                };
                0 < this.length ? this.tail.next = v : this.head = v, this.tail = v, ++this.length
            }
            unshift(v) {
                v = {
                    data: v,
                    next: this.head
                };
                0 === this.length && (this.tail = v), this.head = v, ++this.length
            }
            shift() {
                var ret;
                if (0 !== this.length) return ret = this.head.data, 1 === this.length ? this.head = this.tail = null : this.head = this.head.next, --this.length, ret
            }
            clear() {
                this.head = this.tail = null, this.length = 0
            }
            join(s) {
                if (0 === this.length) return "";
                for (var p = this.head, ret = "" + p.data; p = p.next;) ret += s + p.data;
                return ret
            }
            concat(n) {
                if (0 === this.length) return Buffer.alloc(0);
                for (var src, target, offset, ret = Buffer.allocUnsafe(n >>> 0), p = this.head, i = 0; p;) src = p.data, target = ret, offset = i, Buffer.prototype.copy.call(src, target, offset), i += p.data.length, p = p.next;
                return ret
            }
            consume(n, hasStrings) {
                var ret;
                return n < this.head.data.length ? (ret = this.head.data.slice(0, n), this.head.data = this.head.data.slice(n)) : ret = n === this.head.data.length ? this.shift() : hasStrings ? this._getString(n) : this._getBuffer(n), ret
            }
            first() {
                return this.head.data
            }
            _getString(n) {
                var p = this.head,
                    c = 1,
                    ret = p.data;
                for (n -= ret.length; p = p.next;) {
                    var str = p.data,
                        nb = n > str.length ? str.length : n;
                    if (nb === str.length ? ret += str : ret += str.slice(0, n), 0 === (n -= nb)) {
                        nb === str.length ? (++c, p.next ? this.head = p.next : this.head = this.tail = null) : (this.head = p).data = str.slice(nb);
                        break
                    }++c
                }
                return this.length -= c, ret
            }
            _getBuffer(n) {
                var ret = Buffer.allocUnsafe(n),
                    p = this.head,
                    c = 1;
                for (p.data.copy(ret), n -= p.data.length; p = p.next;) {
                    var buf = p.data,
                        nb = n > buf.length ? buf.length : n;
                    if (buf.copy(ret, ret.length - n, 0, nb), 0 === (n -= nb)) {
                        nb === buf.length ? (++c, p.next ? this.head = p.next : this.head = this.tail = null) : (this.head = p).data = buf.slice(nb);
                        break
                    }++c
                }
                return this.length -= c, ret
            } [require](_, options) {
                return inspect(this, _objectSpread(_objectSpread({}, options), {}, {
                    depth: 0,
                    customInspect: !1
                }))
            }
        }
    }, {
        buffer: 3,
        util: 2
    }],
    24: [function(require, module, exports) {
        ! function(process) {
            ! function() {
                "use strict";

                function emitErrorAndCloseNT(self, err) {
                    emitErrorNT(self, err), emitCloseNT(self)
                }

                function emitCloseNT(self) {
                    self._writableState && !self._writableState.emitClose || self._readableState && !self._readableState.emitClose || self.emit("close")
                }

                function emitErrorNT(self, err) {
                    self.emit("error", err)
                }
                module.exports = {
                    destroy: function(err, cb) {
                        var readableDestroyed = this._readableState && this._readableState.destroyed,
                            writableDestroyed = this._writableState && this._writableState.destroyed;
                        return readableDestroyed || writableDestroyed ? cb ? cb(err) : err && (this._writableState ? this._writableState.errorEmitted || (this._writableState.errorEmitted = !0, process.nextTick(emitErrorNT, this, err)) : process.nextTick(emitErrorNT, this, err)) : (this._readableState && (this._readableState.destroyed = !0), this._writableState && (this._writableState.destroyed = !0), this._destroy(err || null, err => {
                            !cb && err ? this._writableState ? this._writableState.errorEmitted ? process.nextTick(emitCloseNT, this) : (this._writableState.errorEmitted = !0, process.nextTick(emitErrorAndCloseNT, this, err)) : process.nextTick(emitErrorAndCloseNT, this, err) : cb ? (process.nextTick(emitCloseNT, this), cb(err)) : process.nextTick(emitCloseNT, this)
                        })), this
                    },
                    undestroy: function() {
                        this._readableState && (this._readableState.destroyed = !1, this._readableState.reading = !1, this._readableState.ended = !1, this._readableState.endEmitted = !1), this._writableState && (this._writableState.destroyed = !1, this._writableState.ended = !1, this._writableState.ending = !1, this._writableState.finalCalled = !1, this._writableState.prefinished = !1, this._writableState.finished = !1, this._writableState.errorEmitted = !1)
                    },
                    errorOrDestroy: function(stream, err) {
                        var rState = stream._readableState,
                            wState = stream._writableState;
                        rState && rState.autoDestroy || wState && wState.autoDestroy ? stream.destroy(err) : stream.emit("error", err)
                    }
                }
            }.call(this)
        }.call(this, require("_process"))
    }, {
        _process: 9
    }],
    25: [function(require, module, exports) {
        "use strict";
        const ERR_STREAM_PREMATURE_CLOSE = require("../../../errors").codes.ERR_STREAM_PREMATURE_CLOSE;

        function noop() {}
        module.exports = function eos(stream, opts, callback) {
            if ("function" == typeof opts) return eos(stream, null, opts);
            callback = function(callback) {
                let called = !1;
                return function() {
                    if (!called) {
                        called = !0;
                        for (var _len = arguments.length, args = new Array(_len), _key = 0; _key < _len; _key++) args[_key] = arguments[_key];
                        callback.apply(this, args)
                    }
                }
            }(callback || noop);
            let readable = (opts = opts || {}).readable || !1 !== opts.readable && stream.readable,
                writable = opts.writable || !1 !== opts.writable && stream.writable;
            const onlegacyfinish = () => {
                stream.writable || onfinish()
            };
            var writableEnded = stream._writableState && stream._writableState.finished;
            const onfinish = () => {
                writable = !1, writableEnded = !0, readable || callback.call(stream)
            };
            var readableEnded = stream._readableState && stream._readableState.endEmitted;
            const onend = () => {
                    readable = !1, readableEnded = !0, writable || callback.call(stream)
                },
                onerror = err => {
                    callback.call(stream, err)
                },
                onclose = () => {
                    let err;
                    return readable && !readableEnded ? (stream._readableState && stream._readableState.ended || (err = new ERR_STREAM_PREMATURE_CLOSE), callback.call(stream, err)) : writable && !writableEnded ? (stream._writableState && stream._writableState.ended || (err = new ERR_STREAM_PREMATURE_CLOSE), callback.call(stream, err)) : void 0
                },
                onrequest = () => {
                    stream.req.on("finish", onfinish)
                };
            return function(stream) {
                    return stream.setHeader && "function" == typeof stream.abort
                }(stream) ? (stream.on("complete", onfinish), stream.on("abort", onclose), stream.req ? onrequest() : stream.on("request", onrequest)) : writable && !stream._writableState && (stream.on("end", onlegacyfinish), stream.on("close", onlegacyfinish)), stream.on("end", onend), stream.on("finish", onfinish), !1 !== opts.error && stream.on("error", onerror), stream.on("close", onclose),
                function() {
                    stream.removeListener("complete", onfinish), stream.removeListener("abort", onclose), stream.removeListener("request", onrequest), stream.req && stream.req.removeListener("finish", onfinish), stream.removeListener("end", onlegacyfinish), stream.removeListener("close", onlegacyfinish), stream.removeListener("finish", onfinish), stream.removeListener("end", onend), stream.removeListener("error", onerror), stream.removeListener("close", onclose)
                }
        }
    }, {
        "../../../errors": 16
    }],
    26: [function(require, module, exports) {
        module.exports = function() {
            throw new Error("Readable.from is not available in the browser")
        }
    }, {}],
    27: [function(require, module, exports) {
        "use strict";
        let eos;
        const _require$codes = require("../../../errors").codes,
            ERR_MISSING_ARGS = _require$codes.ERR_MISSING_ARGS,
            ERR_STREAM_DESTROYED = _require$codes.ERR_STREAM_DESTROYED;

        function noop(err) {
            if (err) throw err
        }

        function destroyer(stream, reading, writing, callback) {
            callback = function(callback) {
                let called = !1;
                return function() {
                    called || (called = !0, callback(...arguments))
                }
            }(callback);
            let closed = !1,
                destroyed = (stream.on("close", () => {
                    closed = !0
                }), (eos = void 0 === eos ? require("./end-of-stream") : eos)(stream, {
                    readable: reading,
                    writable: writing
                }, err => {
                    if (err) return callback(err);
                    closed = !0, callback()
                }), !1);
            return err => {
                if (!closed && !destroyed) return destroyed = !0,
                    function(stream) {
                        return stream.setHeader && "function" == typeof stream.abort
                    }(stream) ? stream.abort() : "function" == typeof stream.destroy ? stream.destroy() : void callback(err || new ERR_STREAM_DESTROYED("pipe"))
            }
        }

        function call(fn) {
            fn()
        }

        function pipe(from, to) {
            return from.pipe(to)
        }
        module.exports = function() {
            for (var _len = arguments.length, streams = new Array(_len), _key = 0; _key < _len; _key++) streams[_key] = arguments[_key];
            const callback = function(streams) {
                return !streams.length || "function" != typeof streams[streams.length - 1] ? noop : streams.pop()
            }(streams);
            if ((streams = Array.isArray(streams[0]) ? streams[0] : streams).length < 2) throw new ERR_MISSING_ARGS("streams");
            let error;
            const destroys = streams.map(function(stream, i) {
                const reading = i < streams.length - 1;
                return destroyer(stream, reading, 0 < i, function(err) {
                    error = error || err, err && destroys.forEach(call), reading || (destroys.forEach(call), callback(error))
                })
            });
            return streams.reduce(pipe)
        }
    }, {
        "../../../errors": 16,
        "./end-of-stream": 25
    }],
    28: [function(require, module, exports) {
        "use strict";
        const ERR_INVALID_OPT_VALUE = require("../../../errors").codes.ERR_INVALID_OPT_VALUE;
        module.exports = {
            getHighWaterMark: function(state, options, duplexKey, isDuplex) {
                if (null == (options = function(options, isDuplex, duplexKey) {
                        return null != options.highWaterMark ? options.highWaterMark : isDuplex ? options[duplexKey] : null
                    }(options, isDuplex, duplexKey))) return state.objectMode ? 16 : 16384;
                if (!isFinite(options) || Math.floor(options) !== options || options < 0) throw state = isDuplex ? duplexKey : "highWaterMark", new ERR_INVALID_OPT_VALUE(state, options);
                return Math.floor(options)
            }
        }
    }, {
        "../../../errors": 16
    }],
    29: [function(require, module, exports) {
        module.exports = require("events").EventEmitter
    }, {
        events: 5
    }],
    30: [function(require, module, exports) {
        ! function(global) {
            ! function() {
                var ClientRequest = require("./lib/request"),
                    response = require("./lib/response"),
                    extend = require("xtend"),
                    statusCodes = require("builtin-status-codes"),
                    url = require("url"),
                    http = exports;
                http.request = function(opts, cb) {
                    opts = "string" == typeof opts ? url.parse(opts) : extend(opts);
                    var defaultProtocol = -1 === global.location.protocol.search(/^https?:$/) ? "http:" : "",
                        defaultProtocol = opts.protocol || defaultProtocol,
                        host = opts.hostname || opts.host,
                        port = opts.port,
                        path = opts.path || "/",
                        defaultProtocol = (host && -1 !== host.indexOf(":") && (host = "[" + host + "]"), opts.url = (host ? defaultProtocol + "//" + host : "") + (port ? ":" + port : "") + path, opts.method = (opts.method || "GET").toUpperCase(), opts.headers = opts.headers || {}, new ClientRequest(opts));
                    return cb && defaultProtocol.on("response", cb), defaultProtocol
                }, http.get = function(opts, cb) {
                    opts = http.request(opts, cb);
                    return opts.end(), opts
                }, http.ClientRequest = ClientRequest, http.IncomingMessage = response.IncomingMessage, http.Agent = function() {}, http.Agent.defaultMaxSockets = 4, http.globalAgent = new http.Agent, http.STATUS_CODES = statusCodes, http.METHODS = ["CHECKOUT", "CONNECT", "COPY", "DELETE", "GET", "HEAD", "LOCK", "M-SEARCH", "MERGE", "MKACTIVITY", "MKCOL", "MOVE", "NOTIFY", "OPTIONS", "PATCH", "POST", "PROPFIND", "PROPPATCH", "PURGE", "PUT", "REPORT", "SEARCH", "SUBSCRIBE", "TRACE", "UNLOCK", "UNSUBSCRIBE"]
            }.call(this)
        }.call(this, "undefined" != typeof global ? global : "undefined" != typeof self ? self : "undefined" != typeof window ? window : {})
    }, {
        "./lib/request": 32,
        "./lib/response": 33,
        "builtin-status-codes": 4,
        url: 51,
        xtend: 55
    }],
    31: [function(require, module, exports) {
        ! function(global) {
            ! function() {
                var xhr;

                function getXHR() {
                    if (void 0 === xhr)
                        if (global.XMLHttpRequest) {
                            xhr = new global.XMLHttpRequest;
                            try {
                                xhr.open("GET", global.XDomainRequest ? "/" : "https://example.com")
                            } catch (e) {
                                xhr = null
                            }
                        } else xhr = null;
                    return xhr
                }

                function checkTypeSupport(type) {
                    var xhr = getXHR();
                    if (xhr) try {
                        return xhr.responseType = type, xhr.responseType === type
                    } catch (e) {}
                    return !1
                }

                function isFunction(value) {
                    return "function" == typeof value
                }
                exports.fetch = isFunction(global.fetch) && isFunction(global.ReadableStream), exports.writableStream = isFunction(global.WritableStream), exports.abortController = isFunction(global.AbortController), exports.arraybuffer = exports.fetch || checkTypeSupport("arraybuffer"), exports.msstream = !exports.fetch && checkTypeSupport("ms-stream"), exports.mozchunkedarraybuffer = !exports.fetch && checkTypeSupport("moz-chunked-arraybuffer"), exports.overrideMimeType = exports.fetch || !!getXHR() && isFunction(getXHR().overrideMimeType), xhr = null
            }.call(this)
        }.call(this, "undefined" != typeof global ? global : "undefined" != typeof self ? self : "undefined" != typeof window ? window : {})
    }, {}],
    32: [function(require, module, exports) {
        ! function(process, global, Buffer) {
            ! function() {
                var capability = require("./capability"),
                    inherits = require("inherits"),
                    response = require("./response"),
                    stream = require("readable-stream"),
                    IncomingMessage = response.IncomingMessage,
                    rStates = response.readyStates;
                response = module.exports = function(opts) {
                    var preferBinary, self = this,
                        useFetch = (stream.Writable.call(self), self._opts = opts, self._body = [], self._headers = {}, opts.auth && self.setHeader("Authorization", "Basic " + Buffer.from(opts.auth).toString("base64")), Object.keys(opts.headers).forEach(function(name) {
                            self.setHeader(name, opts.headers[name])
                        }), !0);
                    if ("disable-fetch" === opts.mode || "requestTimeout" in opts && !capability.abortController) preferBinary = !(useFetch = !1);
                    else if ("prefer-streaming" === opts.mode) preferBinary = !1;
                    else if ("allow-wrong-content-type" === opts.mode) preferBinary = !capability.overrideMimeType;
                    else {
                        if (opts.mode && "default" !== opts.mode && "prefer-fast" !== opts.mode) throw new Error("Invalid value for opts.mode");
                        preferBinary = !0
                    }
                    self._mode = function(preferBinary, useFetch) {
                        return capability.fetch && useFetch ? "fetch" : capability.mozchunkedarraybuffer ? "moz-chunked-arraybuffer" : capability.msstream ? "ms-stream" : capability.arraybuffer && preferBinary ? "arraybuffer" : "text"
                    }(preferBinary, useFetch), self._fetchTimer = null, self._socketTimeout = null, self._socketTimer = null, self.on("finish", function() {
                        self._onFinish()
                    })
                };
                inherits(response, stream.Writable), response.prototype.setHeader = function(name, value) {
                    var lowerName = name.toLowerCase(); - 1 === unsafeHeaders.indexOf(lowerName) && (this._headers[lowerName] = {
                        name: name,
                        value: value
                    })
                }, response.prototype.getHeader = function(name) {
                    name = this._headers[name.toLowerCase()];
                    return name ? name.value : null
                }, response.prototype.removeHeader = function(name) {
                    delete this._headers[name.toLowerCase()]
                }, response.prototype._onFinish = function() {
                    var self = this;
                    if (!self._destroyed) {
                        var opts = self._opts,
                            headersObj = ("timeout" in opts && 0 !== opts.timeout && self.setTimeout(opts.timeout), self._headers),
                            body = null,
                            headersList = ("GET" !== opts.method && "HEAD" !== opts.method && (body = new Blob(self._body, {
                                type: (headersObj["content-type"] || {}).value || ""
                            })), []);
                        if (Object.keys(headersObj).forEach(function(keyName) {
                                var name = headersObj[keyName].name,
                                    keyName = headersObj[keyName].value;
                                Array.isArray(keyName) ? keyName.forEach(function(v) {
                                    headersList.push([name, v])
                                }) : headersList.push([name, keyName])
                            }), "fetch" === self._mode) {
                            var controller, signal = null;
                            capability.abortController && (signal = (controller = new AbortController).signal, self._fetchAbortController = controller, "requestTimeout" in opts) && 0 !== opts.requestTimeout && (self._fetchTimer = global.setTimeout(function() {
                                self.emit("requestTimeout"), self._fetchAbortController && self._fetchAbortController.abort()
                            }, opts.requestTimeout)), global.fetch(self._opts.url, {
                                method: self._opts.method,
                                headers: headersList,
                                body: body || void 0,
                                mode: "cors",
                                credentials: opts.withCredentials ? "include" : "same-origin",
                                signal: signal
                            }).then(function(response) {
                                self._fetchResponse = response, self._resetTimers(!1), self._connect()
                            }, function(reason) {
                                self._resetTimers(!0), self._destroyed || self.emit("error", reason)
                            })
                        } else {
                            var xhr = self._xhr = new global.XMLHttpRequest;
                            try {
                                xhr.open(self._opts.method, self._opts.url, !0)
                            } catch (err) {
                                return void process.nextTick(function() {
                                    self.emit("error", err)
                                })
                            }
                            "responseType" in xhr && (xhr.responseType = self._mode), "withCredentials" in xhr && (xhr.withCredentials = !!opts.withCredentials), "text" === self._mode && "overrideMimeType" in xhr && xhr.overrideMimeType("text/plain; charset=x-user-defined"), "requestTimeout" in opts && (xhr.timeout = opts.requestTimeout, xhr.ontimeout = function() {
                                self.emit("requestTimeout")
                            }), headersList.forEach(function(header) {
                                xhr.setRequestHeader(header[0], header[1])
                            }), self._response = null, xhr.onreadystatechange = function() {
                                switch (xhr.readyState) {
                                    case rStates.LOADING:
                                    case rStates.DONE:
                                        self._onXHRProgress()
                                }
                            }, "moz-chunked-arraybuffer" === self._mode && (xhr.onprogress = function() {
                                self._onXHRProgress()
                            }), xhr.onerror = function() {
                                self._destroyed || (self._resetTimers(!0), self.emit("error", new Error("XHR error")))
                            };
                            try {
                                xhr.send(body)
                            } catch (err) {
                                process.nextTick(function() {
                                    self.emit("error", err)
                                })
                            }
                        }
                    }
                }, response.prototype._onXHRProgress = function() {
                    this._resetTimers(!1),
                        function(xhr) {
                            try {
                                var status = xhr.status;
                                return null !== status && 0 !== status
                            } catch (e) {}
                        }(this._xhr) && !this._destroyed && (this._response || this._connect(), this._response._onXHRProgress(this._resetTimers.bind(this)))
                }, response.prototype._connect = function() {
                    var self = this;
                    self._destroyed || (self._response = new IncomingMessage(self._xhr, self._fetchResponse, self._mode, self._resetTimers.bind(self)), self._response.on("error", function(err) {
                        self.emit("error", err)
                    }), self.emit("response", self._response))
                }, response.prototype._write = function(chunk, encoding, cb) {
                    this._body.push(chunk), cb()
                }, response.prototype._resetTimers = function(done) {
                    var self = this;
                    global.clearTimeout(self._socketTimer), self._socketTimer = null, done ? (global.clearTimeout(self._fetchTimer), self._fetchTimer = null) : self._socketTimeout && (self._socketTimer = global.setTimeout(function() {
                        self.emit("timeout")
                    }, self._socketTimeout))
                }, response.prototype.abort = response.prototype.destroy = function(err) {
                    this._destroyed = !0, this._resetTimers(!0), this._response && (this._response._destroyed = !0), this._xhr ? this._xhr.abort() : this._fetchAbortController && this._fetchAbortController.abort(), err && this.emit("error", err)
                }, response.prototype.end = function(data, encoding, cb) {
                    "function" == typeof data && (cb = data, data = void 0), stream.Writable.prototype.end.call(this, data, encoding, cb)
                }, response.prototype.setTimeout = function(timeout, cb) {
                    cb && this.once("timeout", cb), this._socketTimeout = timeout, this._resetTimers(!1)
                }, response.prototype.flushHeaders = function() {}, response.prototype.setNoDelay = function() {}, response.prototype.setSocketKeepAlive = function() {};
                var unsafeHeaders = ["accept-charset", "accept-encoding", "access-control-request-headers", "access-control-request-method", "connection", "content-length", "cookie", "cookie2", "date", "dnt", "expect", "host", "keep-alive", "origin", "referer", "te", "trailer", "transfer-encoding", "upgrade", "via"]
            }.call(this)
        }.call(this, require("_process"), "undefined" != typeof global ? global : "undefined" != typeof self ? self : "undefined" != typeof window ? window : {}, require("buffer").Buffer)
    }, {
        "./capability": 31,
        "./response": 33,
        _process: 9,
        buffer: 3,
        inherits: 8,
        "readable-stream": 48
    }],
    33: [function(require, module, exports) {
        ! function(process, global, Buffer) {
            ! function() {
                var capability = require("./capability"),
                    inherits = require("inherits"),
                    stream = require("readable-stream"),
                    rStates = exports.readyStates = {
                        UNSENT: 0,
                        OPENED: 1,
                        HEADERS_RECEIVED: 2,
                        LOADING: 3,
                        DONE: 4
                    },
                    IncomingMessage = exports.IncomingMessage = function(xhr, response, mode, resetTimers) {
                        var self = this;
                        if (stream.Readable.call(self), self._mode = mode, self.headers = {}, self.rawHeaders = [], self.trailers = {}, self.rawTrailers = [], self.on("end", function() {
                                process.nextTick(function() {
                                    self.emit("close")
                                })
                            }), "fetch" === mode) {
                            if (self._fetchResponse = response, self.url = response.url, self.statusCode = response.status, self.statusMessage = response.statusText, response.headers.forEach(function(header, key) {
                                    self.headers[key.toLowerCase()] = header, self.rawHeaders.push(key, header)
                                }), capability.writableStream) {
                                var mode = new WritableStream({
                                    write: function(chunk) {
                                        return resetTimers(!1), new Promise(function(resolve, reject) {
                                            self._destroyed ? reject() : self.push(Buffer.from(chunk)) ? resolve() : self._resumeFetch = resolve
                                        })
                                    },
                                    close: function() {
                                        resetTimers(!0), self._destroyed || self.push(null)
                                    },
                                    abort: function(err) {
                                        resetTimers(!0), self._destroyed || self.emit("error", err)
                                    }
                                });
                                try {
                                    return void response.body.pipeTo(mode).catch(function(err) {
                                        resetTimers(!0), self._destroyed || self.emit("error", err)
                                    })
                                } catch (e) {}
                            }
                            var reader = response.body.getReader();
                            ! function read() {
                                reader.read().then(function(result) {
                                    self._destroyed || (resetTimers(result.done), result.done ? self.push(null) : (self.push(Buffer.from(result.value)), read()))
                                }).catch(function(err) {
                                    resetTimers(!0), self._destroyed || self.emit("error", err)
                                })
                            }()
                        } else self._xhr = xhr, self._pos = 0, self.url = xhr.responseURL, self.statusCode = xhr.status, self.statusMessage = xhr.statusText, xhr.getAllResponseHeaders().split(/\r?\n/).forEach(function(header) {
                            var key, header = header.match(/^([^:]+):\s*(.*)/);
                            header && ("set-cookie" === (key = header[1].toLowerCase()) ? (void 0 === self.headers[key] && (self.headers[key] = []), self.headers[key].push(header[2])) : void 0 !== self.headers[key] ? self.headers[key] += ", " + header[2] : self.headers[key] = header[2], self.rawHeaders.push(header[1], header[2]))
                        }), self._charset = "x-user-defined", capability.overrideMimeType || ((mode = self.rawHeaders["mime-type"]) && (response = mode.match(/;\s*charset=([^;])(;|$)/)) && (self._charset = response[1].toLowerCase()), self._charset) || (self._charset = "utf-8")
                    };
                inherits(IncomingMessage, stream.Readable), IncomingMessage.prototype._read = function() {
                    var resolve = this._resumeFetch;
                    resolve && (this._resumeFetch = null, resolve())
                }, IncomingMessage.prototype._onXHRProgress = function(resetTimers) {
                    var self = this,
                        xhr = self._xhr,
                        response = null;
                    switch (self._mode) {
                        case "text":
                            if ((response = xhr.responseText).length > self._pos) {
                                var newData = response.substr(self._pos);
                                if ("x-user-defined" === self._charset) {
                                    for (var buffer = Buffer.alloc(newData.length), i = 0; i < newData.length; i++) buffer[i] = 255 & newData.charCodeAt(i);
                                    self.push(buffer)
                                } else self.push(newData, self._charset);
                                self._pos = response.length
                            }
                            break;
                        case "arraybuffer":
                            xhr.readyState === rStates.DONE && xhr.response && (response = xhr.response, self.push(Buffer.from(new Uint8Array(response))));
                            break;
                        case "moz-chunked-arraybuffer":
                            response = xhr.response, xhr.readyState === rStates.LOADING && response && self.push(Buffer.from(new Uint8Array(response)));
                            break;
                        case "ms-stream":
                            var reader, response = xhr.response;
                            xhr.readyState === rStates.LOADING && ((reader = new global.MSStreamReader).onprogress = function() {
                                reader.result.byteLength > self._pos && (self.push(Buffer.from(new Uint8Array(reader.result.slice(self._pos)))), self._pos = reader.result.byteLength)
                            }, reader.onload = function() {
                                resetTimers(!0), self.push(null)
                            }, reader.readAsArrayBuffer(response))
                    }
                    self._xhr.readyState === rStates.DONE && "ms-stream" !== self._mode && (resetTimers(!0), self.push(null))
                }
            }.call(this)
        }.call(this, require("_process"), "undefined" != typeof global ? global : "undefined" != typeof self ? self : "undefined" != typeof window ? window : {}, require("buffer").Buffer)
    }, {
        "./capability": 31,
        _process: 9,
        buffer: 3,
        inherits: 8,
        "readable-stream": 48
    }],
    34: [function(require, module, exports) {
        arguments[4][16][0].apply(exports, arguments)
    }, {
        dup: 16
    }],
    35: [function(require, module, exports) {
        arguments[4][17][0].apply(exports, arguments)
    }, {
        "./_stream_readable": 37,
        "./_stream_writable": 39,
        _process: 9,
        dup: 17,
        inherits: 8
    }],
    36: [function(require, module, exports) {
        arguments[4][18][0].apply(exports, arguments)
    }, {
        "./_stream_transform": 38,
        dup: 18,
        inherits: 8
    }],
    37: [function(require, module, exports) {
        arguments[4][19][0].apply(exports, arguments)
    }, {
        "../errors": 34,
        "./_stream_duplex": 35,
        "./internal/streams/async_iterator": 40,
        "./internal/streams/buffer_list": 41,
        "./internal/streams/destroy": 42,
        "./internal/streams/from": 44,
        "./internal/streams/state": 46,
        "./internal/streams/stream": 47,
        _process: 9,
        buffer: 3,
        dup: 19,
        events: 5,
        inherits: 8,
        "string_decoder/": 49,
        util: 2
    }],
    38: [function(require, module, exports) {
        arguments[4][20][0].apply(exports, arguments)
    }, {
        "../errors": 34,
        "./_stream_duplex": 35,
        dup: 20,
        inherits: 8
    }],
    39: [function(require, module, exports) {
        arguments[4][21][0].apply(exports, arguments)
    }, {
        "../errors": 34,
        "./_stream_duplex": 35,
        "./internal/streams/destroy": 42,
        "./internal/streams/state": 46,
        "./internal/streams/stream": 47,
        _process: 9,
        buffer: 3,
        dup: 21,
        inherits: 8,
        "util-deprecate": 53
    }],
    40: [function(require, module, exports) {
        arguments[4][22][0].apply(exports, arguments)
    }, {
        "./end-of-stream": 43,
        _process: 9,
        dup: 22
    }],
    41: [function(require, module, exports) {
        arguments[4][23][0].apply(exports, arguments)
    }, {
        buffer: 3,
        dup: 23,
        util: 2
    }],
    42: [function(require, module, exports) {
        arguments[4][24][0].apply(exports, arguments)
    }, {
        _process: 9,
        dup: 24
    }],
    43: [function(require, module, exports) {
        arguments[4][25][0].apply(exports, arguments)
    }, {
        "../../../errors": 34,
        dup: 25
    }],
    44: [function(require, module, exports) {
        arguments[4][26][0].apply(exports, arguments)
    }, {
        dup: 26
    }],
    45: [function(require, module, exports) {
        arguments[4][27][0].apply(exports, arguments)
    }, {
        "../../../errors": 34,
        "./end-of-stream": 43,
        dup: 27
    }],
    46: [function(require, module, exports) {
        arguments[4][28][0].apply(exports, arguments)
    }, {
        "../../../errors": 34,
        dup: 28
    }],
    47: [function(require, module, exports) {
        arguments[4][29][0].apply(exports, arguments)
    }, {
        dup: 29,
        events: 5
    }],
    48: [function(require, module, exports) {
        (((exports = module.exports = require("./lib/_stream_readable.js")).Stream = exports).Readable = exports).Writable = require("./lib/_stream_writable.js"), exports.Duplex = require("./lib/_stream_duplex.js"), exports.Transform = require("./lib/_stream_transform.js"), exports.PassThrough = require("./lib/_stream_passthrough.js"), exports.finished = require("./lib/internal/streams/end-of-stream.js"), exports.pipeline = require("./lib/internal/streams/pipeline.js")
    }, {
        "./lib/_stream_duplex.js": 35,
        "./lib/_stream_passthrough.js": 36,
        "./lib/_stream_readable.js": 37,
        "./lib/_stream_transform.js": 38,
        "./lib/_stream_writable.js": 39,
        "./lib/internal/streams/end-of-stream.js": 43,
        "./lib/internal/streams/pipeline.js": 45
    }],
    49: [function(require, module, exports) {
        "use strict";
        var Buffer = require("safe-buffer").Buffer,
            isEncoding = Buffer.isEncoding || function(encoding) {
                switch ((encoding = "" + encoding) && encoding.toLowerCase()) {
                    case "hex":
                    case "utf8":
                    case "utf-8":
                    case "ascii":
                    case "binary":
                    case "base64":
                    case "ucs2":
                    case "ucs-2":
                    case "utf16le":
                    case "utf-16le":
                    case "raw":
                        return !0;
                    default:
                        return !1
                }
            };

        function normalizeEncoding(enc) {
            var nenc = function(enc) {
                if (!enc) return "utf8";
                for (var retried;;) switch (enc) {
                    case "utf8":
                    case "utf-8":
                        return "utf8";
                    case "ucs2":
                    case "ucs-2":
                    case "utf16le":
                    case "utf-16le":
                        return "utf16le";
                    case "latin1":
                    case "binary":
                        return "latin1";
                    case "base64":
                    case "ascii":
                    case "hex":
                        return enc;
                    default:
                        if (retried) return;
                        enc = ("" + enc).toLowerCase(), retried = !0
                }
            }(enc);
            if ("string" == typeof nenc || Buffer.isEncoding !== isEncoding && isEncoding(enc)) return nenc || enc;
            throw new Error("Unknown encoding: " + enc)
        }

        function StringDecoder(encoding) {
            var nb;
            switch (this.encoding = normalizeEncoding(encoding), this.encoding) {
                case "utf16le":
                    this.text = utf16Text, this.end = utf16End, nb = 4;
                    break;
                case "utf8":
                    this.fillLast = utf8FillLast, nb = 4;
                    break;
                case "base64":
                    this.text = base64Text, this.end = base64End, nb = 3;
                    break;
                default:
                    return this.write = simpleWrite, void(this.end = simpleEnd)
            }
            this.lastNeed = 0, this.lastTotal = 0, this.lastChar = Buffer.allocUnsafe(nb)
        }

        function utf8CheckByte(byte) {
            return byte <= 127 ? 0 : byte >> 5 == 6 ? 2 : byte >> 4 == 14 ? 3 : byte >> 3 == 30 ? 4 : byte >> 6 == 2 ? -1 : -2
        }

        function utf8FillLast(buf) {
            var p = this.lastTotal - this.lastNeed,
                r = function(self, buf) {
                    return 128 != (192 & buf[0]) ? (self.lastNeed = 0, "�") : 1 < self.lastNeed && 1 < buf.length ? 128 != (192 & buf[1]) ? (self.lastNeed = 1, "�") : 2 < self.lastNeed && 2 < buf.length && 128 != (192 & buf[2]) ? (self.lastNeed = 2, "�") : void 0 : void 0
                }(this, buf);
            return void 0 !== r ? r : this.lastNeed <= buf.length ? (buf.copy(this.lastChar, p, 0, this.lastNeed), this.lastChar.toString(this.encoding, 0, this.lastTotal)) : (buf.copy(this.lastChar, p, 0, buf.length), void(this.lastNeed -= buf.length))
        }

        function utf16Text(buf, i) {
            if ((buf.length - i) % 2 != 0) return this.lastNeed = 1, this.lastTotal = 2, this.lastChar[0] = buf[buf.length - 1], buf.toString("utf16le", i, buf.length - 1);
            i = buf.toString("utf16le", i);
            if (i) {
                var c = i.charCodeAt(i.length - 1);
                if (55296 <= c && c <= 56319) return this.lastNeed = 2, this.lastTotal = 4, this.lastChar[0] = buf[buf.length - 2], this.lastChar[1] = buf[buf.length - 1], i.slice(0, -1)
            }
            return i
        }

        function utf16End(buf) {
            var end, buf = buf && buf.length ? this.write(buf) : "";
            return this.lastNeed ? (end = this.lastTotal - this.lastNeed, buf + this.lastChar.toString("utf16le", 0, end)) : buf
        }

        function base64Text(buf, i) {
            var n = (buf.length - i) % 3;
            return 0 == n ? buf.toString("base64", i) : (this.lastNeed = 3 - n, this.lastTotal = 3, 1 == n ? this.lastChar[0] = buf[buf.length - 1] : (this.lastChar[0] = buf[buf.length - 2], this.lastChar[1] = buf[buf.length - 1]), buf.toString("base64", i, buf.length - n))
        }

        function base64End(buf) {
            buf = buf && buf.length ? this.write(buf) : "";
            return this.lastNeed ? buf + this.lastChar.toString("base64", 0, 3 - this.lastNeed) : buf
        }

        function simpleWrite(buf) {
            return buf.toString(this.encoding)
        }

        function simpleEnd(buf) {
            return buf && buf.length ? this.write(buf) : ""
        }(exports.StringDecoder = StringDecoder).prototype.write = function(buf) {
            if (0 === buf.length) return "";
            var r, i;
            if (this.lastNeed) {
                if (void 0 === (r = this.fillLast(buf))) return "";
                i = this.lastNeed, this.lastNeed = 0
            } else i = 0;
            return i < buf.length ? r ? r + this.text(buf, i) : this.text(buf, i) : r || ""
        }, StringDecoder.prototype.end = function(buf) {
            buf = buf && buf.length ? this.write(buf) : "";
            return this.lastNeed ? buf + "�" : buf
        }, StringDecoder.prototype.text = function(buf, i) {
            var total = function(self, buf, i) {
                var j = buf.length - 1;
                if (!(j < i)) {
                    var nb = utf8CheckByte(buf[j]);
                    if (0 <= nb) return 0 < nb && (self.lastNeed = nb - 1), nb;
                    if (!(--j < i || -2 === nb)) {
                        if (0 <= (nb = utf8CheckByte(buf[j]))) return 0 < nb && (self.lastNeed = nb - 2), nb;
                        if (!(--j < i || -2 === nb) && 0 <= (nb = utf8CheckByte(buf[j]))) return 0 < nb && (2 === nb ? nb = 0 : self.lastNeed = nb - 3), nb
                    }
                }
                return 0
            }(this, buf, i);
            if (!this.lastNeed) return buf.toString("utf8", i);
            this.lastTotal = total;
            total = buf.length - (total - this.lastNeed);
            return buf.copy(this.lastChar, 0, total), buf.toString("utf8", i, total)
        }, StringDecoder.prototype.fillLast = function(buf) {
            if (this.lastNeed <= buf.length) return buf.copy(this.lastChar, this.lastTotal - this.lastNeed, 0, this.lastNeed), this.lastChar.toString(this.encoding, 0, this.lastTotal);
            buf.copy(this.lastChar, this.lastTotal - this.lastNeed, 0, buf.length), this.lastNeed -= buf.length
        }
    }, {
        "safe-buffer": 14
    }],
    50: [function(require, module, exports) {
        ! function(setImmediate, clearImmediate) {
            ! function() {
                var nextTick = require("process/browser.js").nextTick,
                    apply = Function.prototype.apply,
                    slice = Array.prototype.slice,
                    immediateIds = {},
                    nextImmediateId = 0;

                function Timeout(id, clearFn) {
                    this._id = id, this._clearFn = clearFn
                }
                exports.setTimeout = function() {
                    return new Timeout(apply.call(setTimeout, window, arguments), clearTimeout)
                }, exports.setInterval = function() {
                    return new Timeout(apply.call(setInterval, window, arguments), clearInterval)
                }, exports.clearTimeout = exports.clearInterval = function(timeout) {
                    timeout.close()
                }, Timeout.prototype.unref = Timeout.prototype.ref = function() {}, Timeout.prototype.close = function() {
                    this._clearFn.call(window, this._id)
                }, exports.enroll = function(item, msecs) {
                    clearTimeout(item._idleTimeoutId), item._idleTimeout = msecs
                }, exports.unenroll = function(item) {
                    clearTimeout(item._idleTimeoutId), item._idleTimeout = -1
                }, exports._unrefActive = exports.active = function(item) {
                    clearTimeout(item._idleTimeoutId);
                    var msecs = item._idleTimeout;
                    0 <= msecs && (item._idleTimeoutId = setTimeout(function() {
                        item._onTimeout && item._onTimeout()
                    }, msecs))
                }, exports.setImmediate = "function" == typeof setImmediate ? setImmediate : function(fn) {
                    var id = nextImmediateId++,
                        args = !(arguments.length < 2) && slice.call(arguments, 1);
                    return immediateIds[id] = !0, nextTick(function() {
                        immediateIds[id] && (args ? fn.apply(null, args) : fn.call(null), exports.clearImmediate(id))
                    }), id
                }, exports.clearImmediate = "function" == typeof clearImmediate ? clearImmediate : function(id) {
                    delete immediateIds[id]
                }
            }.call(this)
        }.call(this, require("timers").setImmediate, require("timers").clearImmediate)
    }, {
        "process/browser.js": 9,
        timers: 50
    }],
    51: [function(require, module, exports) {
        "use strict";
        var punycode = require("punycode"),
            util = require("./util");

        function Url() {
            this.protocol = null, this.slashes = null, this.auth = null, this.host = null, this.port = null, this.hostname = null, this.hash = null, this.search = null, this.query = null, this.pathname = null, this.path = null, this.href = null
        }
        exports.parse = urlParse, exports.resolve = function(source, relative) {
            return urlParse(source, !1, !0).resolve(relative)
        }, exports.resolveObject = function(source, relative) {
            return source ? urlParse(source, !1, !0).resolveObject(relative) : relative
        }, exports.format = function(obj) {
            util.isString(obj) && (obj = urlParse(obj));
            return obj instanceof Url ? obj.format() : Url.prototype.format.call(obj)
        }, exports.Url = Url;
        var protocolPattern = /^([a-z0-9.+-]+:)/i,
            portPattern = /:[0-9]*$/,
            simplePathPattern = /^(\/\/?(?!\/)[^\?\s]*)(\?[^\s]*)?$/,
            exports = ["{", "}", "|", "\\", "^", "`"].concat(["<", ">", '"', "`", " ", "\r", "\n", "\t"]),
            autoEscape = ["'"].concat(exports),
            nonHostChars = ["%", "/", "?", ";", "#"].concat(autoEscape),
            hostEndingChars = ["/", "?", "#"],
            hostnamePartPattern = /^[+a-z0-9A-Z_-]{0,63}$/,
            hostnamePartStart = /^([+a-z0-9A-Z_-]{0,63})(.*)$/,
            unsafeProtocol = {
                javascript: !0,
                "javascript:": !0
            },
            hostlessProtocol = {
                javascript: !0,
                "javascript:": !0
            },
            slashedProtocol = {
                http: !0,
                https: !0,
                ftp: !0,
                gopher: !0,
                file: !0,
                "http:": !0,
                "https:": !0,
                "ftp:": !0,
                "gopher:": !0,
                "file:": !0
            },
            querystring = require("querystring");

        function urlParse(url, parseQueryString, slashesDenoteHost) {
            var u;
            return url && util.isObject(url) && url instanceof Url ? url : ((u = new Url).parse(url, parseQueryString, slashesDenoteHost), u)
        }
        Url.prototype.parse = function(url, parseQueryString, slashesDenoteHost) {
            if (!util.isString(url)) throw new TypeError("Parameter 'url' must be a string, not " + typeof url);
            var queryIndex = url.indexOf("?"),
                queryIndex = -1 !== queryIndex && queryIndex < url.indexOf("#") ? "?" : "#",
                uSplit = url.split(queryIndex);
            uSplit[0] = uSplit[0].replace(/\\/g, "/");
            var rest = (rest = url = uSplit.join(queryIndex)).trim();
            if (!slashesDenoteHost && 1 === url.split("#").length) {
                uSplit = simplePathPattern.exec(rest);
                if (uSplit) return this.path = rest, this.href = rest, this.pathname = uSplit[1], uSplit[2] ? (this.search = uSplit[2], this.query = parseQueryString ? querystring.parse(this.search.substr(1)) : this.search.substr(1)) : parseQueryString && (this.search = "", this.query = {}), this
            }
            var lowerProto, queryIndex = protocolPattern.exec(rest);
            if (queryIndex && (lowerProto = (queryIndex = queryIndex[0]).toLowerCase(), this.protocol = lowerProto, rest = rest.substr(queryIndex.length)), !(slashesDenoteHost || queryIndex || rest.match(/^\/\/[^@\/]+@[^@\/]+/)) || !(slashes = "//" === rest.substr(0, 2)) || queryIndex && hostlessProtocol[queryIndex] || (rest = rest.substr(2), this.slashes = !0), !hostlessProtocol[queryIndex] && (slashes || queryIndex && !slashedProtocol[queryIndex])) {
                for (var hostEnd = -1, i = 0; i < hostEndingChars.length; i++) - 1 !== (hec = rest.indexOf(hostEndingChars[i])) && (-1 === hostEnd || hec < hostEnd) && (hostEnd = hec); - 1 !== (url = -1 === hostEnd ? rest.lastIndexOf("@") : rest.lastIndexOf("@", hostEnd)) && (uSplit = rest.slice(0, url), rest = rest.slice(url + 1), this.auth = decodeURIComponent(uSplit));
                for (var hec, hostEnd = -1, i = 0; i < nonHostChars.length; i++) - 1 !== (hec = rest.indexOf(nonHostChars[i])) && (-1 === hostEnd || hec < hostEnd) && (hostEnd = hec); - 1 === hostEnd && (hostEnd = rest.length), this.host = rest.slice(0, hostEnd), rest = rest.slice(hostEnd), this.parseHost(), this.hostname = this.hostname || "";
                slashesDenoteHost = "[" === this.hostname[0] && "]" === this.hostname[this.hostname.length - 1];
                if (!slashesDenoteHost)
                    for (var hostparts = this.hostname.split(/\./), i = 0, l = hostparts.length; i < l; i++) {
                        var part = hostparts[i];
                        if (part && !part.match(hostnamePartPattern)) {
                            for (var newpart = "", j = 0, k = part.length; j < k; j++) 127 < part.charCodeAt(j) ? newpart += "x" : newpart += part[j];
                            if (!newpart.match(hostnamePartPattern)) {
                                var validParts = hostparts.slice(0, i),
                                    notHost = hostparts.slice(i + 1),
                                    bit = part.match(hostnamePartStart);
                                bit && (validParts.push(bit[1]), notHost.unshift(bit[2])), notHost.length && (rest = "/" + notHost.join(".") + rest), this.hostname = validParts.join(".");
                                break
                            }
                        }
                    }
                255 < this.hostname.length ? this.hostname = "" : this.hostname = this.hostname.toLowerCase(), slashesDenoteHost || (this.hostname = punycode.toASCII(this.hostname));
                var p = this.port ? ":" + this.port : "",
                    slashes = this.hostname || "";
                this.host = slashes + p, this.href += this.host, slashesDenoteHost && (this.hostname = this.hostname.substr(1, this.hostname.length - 2), "/" !== rest[0]) && (rest = "/" + rest)
            }
            if (!unsafeProtocol[lowerProto])
                for (i = 0, l = autoEscape.length; i < l; i++) {
                    var esc, ae = autoEscape[i]; - 1 !== rest.indexOf(ae) && ((esc = encodeURIComponent(ae)) === ae && (esc = escape(ae)), rest = rest.split(ae).join(esc))
                }
            queryIndex = rest.indexOf("#"), -1 !== queryIndex && (this.hash = rest.substr(queryIndex), rest = rest.slice(0, queryIndex)), url = rest.indexOf("?");
            return -1 !== url ? (this.search = rest.substr(url), this.query = rest.substr(url + 1), parseQueryString && (this.query = querystring.parse(this.query)), rest = rest.slice(0, url)) : parseQueryString && (this.search = "", this.query = {}), rest && (this.pathname = rest), slashedProtocol[lowerProto] && this.hostname && !this.pathname && (this.pathname = "/"), (this.pathname || this.search) && (p = this.pathname || "", uSplit = this.search || "", this.path = p + uSplit), this.href = this.format(), this
        }, Url.prototype.format = function() {
            var auth = this.auth || "",
                protocol = (auth && (auth = (auth = encodeURIComponent(auth)).replace(/%3A/i, ":"), auth += "@"), this.protocol || ""),
                pathname = this.pathname || "",
                hash = this.hash || "",
                host = !1,
                query = "",
                auth = (this.host ? host = auth + this.host : this.hostname && (host = auth + (-1 === this.hostname.indexOf(":") ? this.hostname : "[" + this.hostname + "]"), this.port) && (host += ":" + this.port), this.query && util.isObject(this.query) && Object.keys(this.query).length && (query = querystring.stringify(this.query)), this.search || query && "?" + query || "");
            return protocol && ":" !== protocol.substr(-1) && (protocol += ":"), this.slashes || (!protocol || slashedProtocol[protocol]) && !1 !== host ? (host = "//" + (host || ""), pathname && "/" !== pathname.charAt(0) && (pathname = "/" + pathname)) : host = host || "", hash && "#" !== hash.charAt(0) && (hash = "#" + hash), auth && "?" !== auth.charAt(0) && (auth = "?" + auth), protocol + host + (pathname = pathname.replace(/[?#]/g, function(match) {
                return encodeURIComponent(match)
            })) + (auth = auth.replace("#", "%23")) + hash
        }, Url.prototype.resolve = function(relative) {
            return this.resolveObject(urlParse(relative, !1, !0)).format()
        }, Url.prototype.resolveObject = function(relative) {
            util.isString(relative) && ((rel = new Url).parse(relative, !1, !0), relative = rel);
            for (var result = new Url, tkeys = Object.keys(this), tk = 0; tk < tkeys.length; tk++) {
                var tkey = tkeys[tk];
                result[tkey] = this[tkey]
            }
            if (result.hash = relative.hash, "" !== relative.href)
                if (relative.slashes && !relative.protocol) {
                    for (var rkeys = Object.keys(relative), rk = 0; rk < rkeys.length; rk++) {
                        var rkey = rkeys[rk];
                        "protocol" !== rkey && (result[rkey] = relative[rkey])
                    }
                    slashedProtocol[result.protocol] && result.hostname && !result.pathname && (result.path = result.pathname = "/")
                } else if (relative.protocol && relative.protocol !== result.protocol)
                if (slashedProtocol[relative.protocol]) {
                    if (result.protocol = relative.protocol, relative.host || hostlessProtocol[relative.protocol]) result.pathname = relative.pathname;
                    else {
                        for (var relPath = (relative.pathname || "").split("/"); relPath.length && !(relative.host = relPath.shift()););
                        relative.host || (relative.host = ""), relative.hostname || (relative.hostname = ""), "" !== relPath[0] && relPath.unshift(""), relPath.length < 2 && relPath.unshift(""), result.pathname = relPath.join("/")
                    }
                    result.search = relative.search, result.query = relative.query, result.host = relative.host || "", result.auth = relative.auth, result.hostname = relative.hostname || relative.host, result.port = relative.port, (result.pathname || result.search) && (rel = result.pathname || "", s = result.search || "", result.path = rel + s), result.slashes = result.slashes || relative.slashes
                } else
                    for (var keys = Object.keys(relative), v = 0; v < keys.length; v++) {
                        var k = keys[v];
                        result[k] = relative[k]
                    } else {
                        var rel = result.pathname && "/" === result.pathname.charAt(0),
                            s = relative.host || relative.pathname && "/" === relative.pathname.charAt(0),
                            rel = s || rel || result.host && relative.pathname,
                            removeAllDots = rel,
                            srcPath = result.pathname && result.pathname.split("/") || [],
                            relPath = relative.pathname && relative.pathname.split("/") || [],
                            psychotic = result.protocol && !slashedProtocol[result.protocol];
                        if (psychotic && (result.hostname = "", result.port = null, result.host && ("" === srcPath[0] ? srcPath[0] = result.host : srcPath.unshift(result.host)), result.host = "", relative.protocol && (relative.hostname = null, relative.port = null, relative.host && ("" === relPath[0] ? relPath[0] = relative.host : relPath.unshift(relative.host)), relative.host = null), rel = rel && ("" === relPath[0] || "" === srcPath[0])), s) result.host = (relative.host || "" === relative.host ? relative : result).host, result.hostname = (relative.hostname || "" === relative.hostname ? relative : result).hostname, result.search = relative.search, result.query = relative.query, srcPath = relPath;
                        else if (relPath.length)(srcPath = srcPath || []).pop(), srcPath = srcPath.concat(relPath), result.search = relative.search, result.query = relative.query;
                        else if (!util.isNullOrUndefined(relative.search)) return psychotic && (result.hostname = result.host = srcPath.shift(), authInHost = !!(result.host && 0 < result.host.indexOf("@")) && result.host.split("@")) && (result.auth = authInHost.shift(), result.host = result.hostname = authInHost.shift()), result.search = relative.search, result.query = relative.query, util.isNull(result.pathname) && util.isNull(result.search) || (result.path = (result.pathname || "") + (result.search || "")), result.href = result.format(), result;
                        if (srcPath.length) {
                            for (var last = srcPath.slice(-1)[0], s = (result.host || relative.host || 1 < srcPath.length) && ("." === last || ".." === last) || "" === last, up = 0, i = srcPath.length; 0 <= i; i--) "." === (last = srcPath[i]) ? srcPath.splice(i, 1) : ".." === last ? (srcPath.splice(i, 1), up++) : up && (srcPath.splice(i, 1), up--);
                            if (!rel && !removeAllDots)
                                for (; up--;) srcPath.unshift("..");
                            !rel || "" === srcPath[0] || srcPath[0] && "/" === srcPath[0].charAt(0) || srcPath.unshift(""), s && "/" !== srcPath.join("/").substr(-1) && srcPath.push("");
                            var authInHost, removeAllDots = "" === srcPath[0] || srcPath[0] && "/" === srcPath[0].charAt(0);
                            psychotic && (result.hostname = result.host = !removeAllDots && srcPath.length ? srcPath.shift() : "", authInHost = !!(result.host && 0 < result.host.indexOf("@")) && result.host.split("@")) && (result.auth = authInHost.shift(), result.host = result.hostname = authInHost.shift()), (rel = rel || result.host && srcPath.length) && !removeAllDots && srcPath.unshift(""), srcPath.length ? result.pathname = srcPath.join("/") : (result.pathname = null, result.path = null), util.isNull(result.pathname) && util.isNull(result.search) || (result.path = (result.pathname || "") + (result.search || "")), result.auth = relative.auth || result.auth, result.slashes = result.slashes || relative.slashes
                        } else result.pathname = null, result.search ? result.path = "/" + result.search : result.path = null
                    }
            return result.href = result.format(), result
        }, Url.prototype.parseHost = function() {
            var host = this.host,
                port = portPattern.exec(host);
            port && (":" !== (port = port[0]) && (this.port = port.substr(1)), host = host.substr(0, host.length - port.length)), host && (this.hostname = host)
        }
    }, {
        "./util": 52,
        punycode: 10,
        querystring: 13
    }],
    52: [function(require, module, exports) {
        "use strict";
        module.exports = {
            isString: function(arg) {
                return "string" == typeof arg
            },
            isObject: function(arg) {
                return "object" == typeof arg && null !== arg
            },
            isNull: function(arg) {
                return null === arg
            },
            isNullOrUndefined: function(arg) {
                return null == arg
            }
        }
    }, {}],
    53: [function(require, module, exports) {
        ! function(global) {
            ! function() {
                function config(name) {
                    try {
                        if (!global.localStorage) return
                    } catch (_) {
                        return
                    }
                    name = global.localStorage[name];
                    return null != name && "true" === String(name).toLowerCase()
                }
                module.exports = function(fn, msg) {
                    if (config("noDeprecation")) return fn;
                    var warned = !1;
                    return function() {
                        if (!warned) {
                            if (config("throwDeprecation")) throw new Error(msg);
                            config("traceDeprecation") ? console.trace(msg) : console.warn(msg), warned = !0
                        }
                        return fn.apply(this, arguments)
                    }
                }
            }.call(this)
        }.call(this, "undefined" != typeof global ? global : "undefined" != typeof self ? self : "undefined" != typeof window ? window : {})
    }, {}],
    54: [function(require, module, exports) {
        var indexOf = function(xs, item) {
                if (xs.indexOf) return xs.indexOf(item);
                for (var i = 0; i < xs.length; i++)
                    if (xs[i] === item) return i;
                return -1
            },
            Object_keys = function(obj) {
                if (Object.keys) return Object.keys(obj);
                var key, res = [];
                for (key in obj) res.push(key);
                return res
            },
            forEach = function(xs, fn) {
                if (xs.forEach) return xs.forEach(fn);
                for (var i = 0; i < xs.length; i++) fn(xs[i], i, xs)
            },
            defineProp = function() {
                try {
                    return Object.defineProperty({}, "_", {}),
                        function(obj, name, value) {
                            Object.defineProperty(obj, name, {
                                writable: !0,
                                enumerable: !1,
                                configurable: !0,
                                value: value
                            })
                        }
                } catch (e) {
                    return function(obj, name, value) {
                        obj[name] = value
                    }
                }
            }(),
            globals = ["Array", "Boolean", "Date", "Error", "EvalError", "Function", "Infinity", "JSON", "Math", "NaN", "Number", "Object", "RangeError", "ReferenceError", "RegExp", "String", "SyntaxError", "TypeError", "URIError", "decodeURI", "decodeURIComponent", "encodeURI", "encodeURIComponent", "escape", "eval", "isFinite", "isNaN", "parseFloat", "parseInt", "undefined", "unescape"];

        function Context() {}
        Context.prototype = {};
        var Script = exports.Script = function(code) {
            if (!(this instanceof Script)) return new Script(code);
            this.code = code
        };
        Script.prototype.runInContext = function(context) {
            var iframe, win, wEval, winKeys, wExecScript;
            if (context instanceof Context) return (iframe = document.createElement("iframe")).style || (iframe.style = {}), iframe.style.display = "none", document.body.appendChild(iframe), wEval = (win = iframe.contentWindow).eval, wExecScript = win.execScript, !wEval && wExecScript && (wExecScript.call(win, "null"), wEval = win.eval), forEach(Object_keys(context), function(key) {
                win[key] = context[key]
            }), forEach(globals, function(key) {
                context[key] && (win[key] = context[key])
            }), winKeys = Object_keys(win), wExecScript = wEval.call(win, this.code), forEach(Object_keys(win), function(key) {
                (key in context || -1 === indexOf(winKeys, key)) && (context[key] = win[key])
            }), forEach(globals, function(key) {
                key in context || defineProp(context, key, win[key])
            }), document.body.removeChild(iframe), wExecScript;
            throw new TypeError("needs a 'context' argument.")
        }, Script.prototype.runInThisContext = function() {
            return eval(this.code)
        }, Script.prototype.runInNewContext = function(context) {
            var ctx = Script.createContext(context),
                res = this.runInContext(ctx);
            return context && forEach(Object_keys(ctx), function(key) {
                context[key] = ctx[key]
            }), res
        }, forEach(Object_keys(Script.prototype), function(name) {
            exports[name] = Script[name] = function(code) {
                var s = Script(code);
                return s[name].apply(s, [].slice.call(arguments, 1))
            }
        }), exports.isContext = function(context) {
            return context instanceof Context
        }, exports.createScript = function(code) {
            return exports.Script(code)
        }, exports.createContext = Script.createContext = function(context) {
            var copy = new Context;
            return "object" == typeof context && forEach(Object_keys(context), function(key) {
                copy[key] = context[key]
            }), copy
        }
    }, {}],
    55: [function(require, module, exports) {
        module.exports = function() {
            for (var target = {}, i = 0; i < arguments.length; i++) {
                var key, source = arguments[i];
                for (key in source) hasOwnProperty.call(source, key) && (target[key] = source[key])
            }
            return target
        };
        var hasOwnProperty = Object.prototype.hasOwnProperty
    }, {}],
    56: [function(require, module, exports) {
        require = require("ytdl-core");
        module.exports = require
    }, {
        "ytdl-core": 67
    }],
    57: [function(require, module, exports) {
        "use strict";
        var __importDefault = this && this.__importDefault || function(mod) {
                return mod && mod.__esModule ? mod : {
                    default: mod
                }
            },
            stream_1 = (Object.defineProperty(exports, "__esModule", {
                value: !0
            }), require("stream"));
        const sax_1 = __importDefault(require("sax")),
            parse_time_1 = require("./parse-time");
        class DashMPDParser extends stream_1.Writable {
            constructor(targetID) {
                super(), this._parser = sax_1.default.createStream(!1, {
                    lowercase: !0
                }), this._parser.on("error", this.destroy.bind(this));
                let lastTag, currtime = 0,
                    seq = 0,
                    segmentTemplate, timescale, offset, duration, baseURL, timeline = [],
                    getSegments = !1,
                    gotSegments = !1,
                    isStatic, treeLevel, periodStart;
                const tmpl = str => {
                        const context = {
                            RepresentationID: targetID,
                            Number: seq,
                            Time: currtime
                        };
                        return str.replace(/\$(\w+)\$/g, (m, p1) => "" + context[p1])
                    },
                    onEnd = (this._parser.on("opentag", node => {
                        switch (node.name) {
                            case "mpd":
                                currtime = node.attributes.availabilitystarttime ? new Date(node.attributes.availabilitystarttime).getTime() : 0, isStatic = "dynamic" !== node.attributes.type;
                                break;
                            case "period":
                                seq = 0, timescale = 1e3, duration = 0, offset = 0, baseURL = [], treeLevel = 0, periodStart = parse_time_1.durationStr(node.attributes.start) || 0;
                                break;
                            case "segmentlist":
                                seq = parseInt(node.attributes.startnumber) || seq, timescale = parseInt(node.attributes.timescale) || timescale, duration = parseInt(node.attributes.duration) || duration, offset = parseInt(node.attributes.presentationtimeoffset) || offset;
                                break;
                            case "segmenttemplate":
                                segmentTemplate = node.attributes, seq = parseInt(node.attributes.startnumber) || seq, timescale = parseInt(node.attributes.timescale) || timescale;
                                break;
                            case "segmenttimeline":
                            case "baseurl":
                                lastTag = node.name;
                                break;
                            case "s":
                                timeline.push({
                                    duration: parseInt(node.attributes.d),
                                    repeat: parseInt(node.attributes.r),
                                    time: parseInt(node.attributes.t)
                                });
                                break;
                            case "adaptationset":
                            case "representation":
                                treeLevel++, targetID = targetID || node.attributes.id, (getSegments = node.attributes.id === "" + targetID) && (periodStart && (currtime += periodStart), offset && (currtime -= offset / timescale * 1e3), this.emit("starttime", currtime));
                                break;
                            case "initialization":
                                getSegments && this.emit("item", {
                                    url: baseURL.filter(s => !!s).join("") + node.attributes.sourceurl,
                                    seq: seq,
                                    init: !0,
                                    duration: 0
                                });
                                break;
                            case "segmenturl":
                                var tl;
                                getSegments && (gotSegments = !0, tl = ((null == (tl = timeline.shift()) ? void 0 : tl.duration) || duration) / timescale * 1e3, this.emit("item", {
                                    url: baseURL.filter(s => !!s).join("") + node.attributes.media,
                                    seq: seq++,
                                    duration: tl
                                }), currtime += tl)
                        }
                    }), () => {
                        isStatic && this.emit("endlist"), getSegments ? this.emit("end") : this.destroy(Error(`Representation '${targetID}' not found`))
                    });
                this._parser.on("closetag", tagName => {
                    switch (tagName) {
                        case "adaptationset":
                        case "representation":
                            if (treeLevel--, segmentTemplate && timeline.length) {
                                gotSegments = !0, segmentTemplate.initialization && this.emit("item", {
                                    url: baseURL.filter(s => !!s).join("") + tmpl(segmentTemplate.initialization),
                                    seq: seq,
                                    init: !0,
                                    duration: 0
                                });
                                for (var {
                                        duration: itemDuration,
                                        repeat,
                                        time
                                    }
                                    of timeline) {
                                    itemDuration = itemDuration / timescale * 1e3, repeat = repeat || 1, currtime = time || currtime;
                                    for (let i = 0; i < repeat; i++) this.emit("item", {
                                        url: baseURL.filter(s => !!s).join("") + tmpl(segmentTemplate.media),
                                        seq: seq++,
                                        duration: itemDuration
                                    }), currtime += itemDuration
                                }
                            }
                            gotSegments && (this.emit("endearly"), onEnd(), this._parser.removeAllListeners(), this.removeAllListeners("finish"))
                    }
                }), this._parser.on("text", text => {
                    "baseurl" === lastTag && (baseURL[treeLevel] = text, lastTag = null)
                }), this.on("finish", onEnd)
            }
            _write(chunk, encoding, callback) {
                this._parser.write(chunk), callback()
            }
        }
        exports.default = DashMPDParser
    }, {
        "./parse-time": 60,
        sax: 63,
        stream: 15
    }],
    58: [function(require, module, exports) {
        "use strict";
        var __importDefault = this && this.__importDefault || function(mod) {
            return mod && mod.__esModule ? mod : {
                default: mod
            }
        };
        const stream_1 = require("stream"),
            miniget_1 = __importDefault(require("miniget"));
        var m3u8_parser_1 = __importDefault(require("./m3u8-parser")),
            __importDefault = __importDefault(require("./dash-mpd-parser"));
        const queue_1 = require("./queue"),
            parse_time_1 = require("./parse-time"),
            supportedParsers = {
                m3u8: m3u8_parser_1.default,
                "dash-mpd": __importDefault.default
            };
        require = (playlistURL, options = {}) => {
            const stream = new stream_1.PassThrough({
                highWaterMark: options.highWaterMark
            });
            var chunkReadahead = options.chunkReadahead || 3;
            const liveBuffer = options.liveBuffer || 2e4,
                requestOptions = options.requestOptions,
                Parser = supportedParsers[options.parser || (/\.mpd$/.test(playlistURL) ? "dash-mpd" : "m3u8")];
            if (!Parser) throw TypeError(`parser '${options.parser}' not supported`);
            let begin = 0;
            void 0 !== options.begin && (begin = "string" == typeof options.begin ? parse_time_1.humanStr(options.begin) : Math.max(options.begin - liveBuffer, 0));
            const forwardEvents = req => {
                for (var event of ["abort", "request", "response", "redirect", "retry", "reconnect"]) req.on(event, stream.emit.bind(stream, event))
            };
            let currSegment;
            const streamQueue = new queue_1.Queue((req, callback) => {
                currSegment = req;
                let size = 0;
                req.on("data", chunk => size += chunk.length), req.pipe(stream, {
                    end: !1
                }), req.on("end", () => callback(null, size))
            }, {
                concurrency: 1
            });
            let segmentNumber = 0,
                downloaded = 0;
            const requestQueue = new queue_1.Queue((segment, callback) => {
                    var reqOptions = Object.assign({}, requestOptions),
                        reqOptions = (segment.range && (reqOptions.headers = Object.assign({}, reqOptions.headers, {
                            Range: `bytes=${segment.range.start}-` + segment.range.end
                        })), miniget_1.default(new URL(segment.url, playlistURL).toString(), reqOptions));
                    reqOptions.on("error", callback), forwardEvents(reqOptions), streamQueue.push(reqOptions, (_, size) => {
                        downloaded += +size, stream.emit("progress", {
                            num: ++segmentNumber,
                            size: size,
                            duration: segment.duration,
                            url: segment.url
                        }, requestQueue.total, downloaded), callback(null)
                    })
                }, {
                    concurrency: chunkReadahead
                }),
                onError = err => {
                    stream.emit("error", err), stream.end()
                };
            let refreshThreshold, minRefreshTime, refreshTimeout, fetchingPlaylist = !0,
                ended = !1,
                isStatic = !1,
                lastRefresh;
            const onQueuedEnd = err => {
                currSegment = null, err ? onError(err) : !fetchingPlaylist && !ended && !isStatic && requestQueue.tasks.length + requestQueue.active <= refreshThreshold ? (err = Math.max(0, minRefreshTime - (Date.now() - lastRefresh)), fetchingPlaylist = !0, refreshTimeout = setTimeout(refreshPlaylist, err)) : !ended && !isStatic || requestQueue.tasks.length || requestQueue.active || stream.end()
            };
            let currPlaylist, lastSeq, starttime = 0;
            const refreshPlaylist = () => {
                lastRefresh = Date.now(), (currPlaylist = miniget_1.default(playlistURL, requestOptions)).on("error", onError), forwardEvents(currPlaylist);
                var parser = currPlaylist.pipe(new Parser(options.id));
                parser.on("starttime", a => {
                    starttime || (starttime = a, "string" == typeof options.begin && 0 <= begin && (begin += starttime))
                }), parser.on("endlist", () => {
                    isStatic = !0
                }), parser.on("endearly", currPlaylist.unpipe.bind(currPlaylist, parser));
                let addedItems = [];
                const addItem = item => {
                    if (!item.init) {
                        if (item.seq <= lastSeq) return;
                        lastSeq = item.seq
                    }
                    begin = item.time, requestQueue.push(item, onQueuedEnd), addedItems.push(item)
                };
                let tailedItems = [],
                    tailedItemsDuration = 0;
                parser.on("item", item => {
                    item = Object.assign({
                        time: starttime
                    }, item);
                    if (begin <= item.time) addItem(item);
                    else
                        for (tailedItems.push(item), tailedItemsDuration += item.duration; 1 < tailedItems.length && tailedItemsDuration - tailedItems[0].duration > liveBuffer;) {
                            var lastItem = tailedItems.shift();
                            tailedItemsDuration -= lastItem.duration
                        }
                    starttime += item.duration
                }), parser.on("end", () => {
                    currPlaylist = null, !addedItems.length && tailedItems.length && tailedItems.forEach(item => {
                        addItem(item)
                    }), refreshThreshold = Math.max(1, Math.ceil(.01 * addedItems.length)), minRefreshTime = addedItems.reduce((total, item) => item.duration + total, 0), fetchingPlaylist = !1, onQueuedEnd(null)
                })
            };
            return refreshPlaylist(), stream.end = () => (ended = !0, streamQueue.die(), requestQueue.die(), clearTimeout(refreshTimeout), null !== currPlaylist && void 0 !== currPlaylist && currPlaylist.destroy(), null !== currSegment && void 0 !== currSegment && currSegment.destroy(), stream_1.PassThrough.prototype.end.call(stream, null), stream), stream
        };
        require.parseTimestamp = parse_time_1.humanStr, module.exports = require
    }, {
        "./dash-mpd-parser": 57,
        "./m3u8-parser": 59,
        "./parse-time": 60,
        "./queue": 61,
        miniget: 62,
        stream: 15
    }],
    59: [function(require, module, exports) {
        "use strict";
        Object.defineProperty(exports, "__esModule", {
            value: !0
        });
        class m3u8Parser extends require("stream").Writable {
            constructor() {
                super(), this._lastLine = "", this._seq = 0, this._nextItemDuration = null, this._nextItemRange = null, this._lastItemRangeEnd = 0, this.on("finish", () => {
                    this._parseLine(this._lastLine), this.emit("end")
                })
            }
            _parseAttrList(value) {
                for (var match, attrs = {}, regex = /([A-Z0-9-]+)=(?:"([^"]*?)"|([^,]*?))/g; null !== (match = regex.exec(value));) attrs[match[1]] = match[2] || match[3];
                return attrs
            }
            _parseRange(value) {
                var start;
                return value ? (start = {
                    start: start = (value = value.split("@"))[1] ? parseInt(value[1]) : this._lastItemRangeEnd + 1,
                    end: start + parseInt(value[0]) - 1
                }, this._lastItemRangeEnd = start.end, start) : null
            }
            _parseLine(line) {
                var match = line.match(/^#(EXT[A-Z0-9-]+)(?::(.*))?/);
                if (match) {
                    var tag = match[1],
                        value = match[2] || "";
                    switch (tag) {
                        case "EXT-X-PROGRAM-DATE-TIME":
                            this.emit("starttime", new Date(value).getTime());
                            break;
                        case "EXT-X-MEDIA-SEQUENCE":
                            this._seq = parseInt(value);
                            break;
                        case "EXT-X-MAP":
                            var attrs = this._parseAttrList(value);
                            if (!attrs.URI) return void this.destroy(new Error("`EXT-X-MAP` found without required attribute `URI`"));
                            this.emit("item", {
                                url: attrs.URI,
                                seq: this._seq,
                                init: !0,
                                duration: 0,
                                range: this._parseRange(attrs.BYTERANGE)
                            });
                            break;
                        case "EXT-X-BYTERANGE":
                            this._nextItemRange = this._parseRange(value);
                            break;
                        case "EXTINF":
                            this._nextItemDuration = Math.round(1e3 * parseFloat(value.split(",")[0]));
                            break;
                        case "EXT-X-ENDLIST":
                            this.emit("endlist")
                    }
                } else !/^#/.test(line) && line.trim() && (this.emit("item", {
                    url: line.trim(),
                    seq: this._seq++,
                    duration: this._nextItemDuration,
                    range: this._nextItemRange
                }), this._nextItemRange = null)
            }
            _write(chunk, encoding, callback) {
                let lines = chunk.toString("utf8").split("\n");
                this._lastLine && (lines[0] = this._lastLine + lines[0]), lines.forEach((line, i) => {
                    this.destroyed || (i < lines.length - 1 ? this._parseLine(line) : this._lastLine = line)
                }), callback()
            }
        }
        exports.default = m3u8Parser
    }, {
        stream: 15
    }],
    60: [function(require, module, exports) {
        "use strict";
        Object.defineProperty(exports, "__esModule", {
            value: !0
        }), exports.durationStr = exports.humanStr = void 0;
        const numberFormat = /^\d+$/,
            timeFormat = /^(?:(?:(\d+):)?(\d{1,2}):)?(\d{1,2})(?:\.(\d{3}))?$/,
            timeUnits = {
                ms: 1,
                s: 1e3,
                m: 6e4,
                h: 36e5
            };
        exports.humanStr = time => {
            if ("number" == typeof time) return time;
            if (numberFormat.test(time)) return +time;
            var firstFormat = timeFormat.exec(time);
            if (firstFormat) return +(firstFormat[1] || 0) * timeUnits.h + +(firstFormat[2] || 0) * timeUnits.m + +firstFormat[3] * timeUnits.s + +(firstFormat[4] || 0); {
                let total = 0;
                for (var rs, r = /(-?\d+)(ms|s|m|h)/g; null !== (rs = r.exec(time));) total += +rs[1] * timeUnits[rs[2]];
                return total
            }
        }, exports.durationStr = time => {
            let total = 0;
            for (var rs, r = /(\d+(?:\.\d+)?)(S|M|H)/g; null !== (rs = r.exec(time));) total += +rs[1] * timeUnits[rs[2].toLowerCase()];
            return total
        }
    }, {}],
    61: [function(require, module, exports) {
        "use strict";
        Object.defineProperty(exports, "__esModule", {
            value: !0
        }), exports.Queue = void 0;
        exports.Queue = class {
            constructor(worker, options = {}) {
                this._worker = worker, this._concurrency = options.concurrency || 1, this.tasks = [], this.total = 0, this.active = 0
            }
            push(item, callback) {
                this.tasks.push({
                    item: item,
                    callback: callback
                }), this.total++, this._next()
            }
            _next() {
                if (!(this.active >= this._concurrency) && this.tasks.length) {
                    const {
                        item,
                        callback
                    } = this.tasks.shift();
                    let callbackCalled = !1;
                    this.active++, this._worker(item, (err, result) => {
                        callbackCalled || (this.active--, callbackCalled = !0, null !== callback && void 0 !== callback && callback(err, result), this._next())
                    })
                }
            }
            die() {
                this.tasks = []
            }
        }
    }, {}],
    62: [function(require, module, exports) {
        ! function(process) {
            ! function() {
                "use strict";
                var __importDefault = this && this.__importDefault || function(mod) {
                        return mod && mod.__esModule ? mod : {
                            default: mod
                        }
                    },
                    http_1 = __importDefault(require("http")),
                    __importDefault = __importDefault(require("https"));
                const stream_1 = require("stream"),
                    httpLibs = {
                        "http:": http_1.default,
                        "https:": __importDefault.default
                    },
                    redirectStatusCodes = new Set([301, 302, 303, 307, 308]),
                    retryStatusCodes = new Set([429, 503]),
                    requestEvents = ["connect", "continue", "information", "socket", "timeout", "upgrade"],
                    responseEvents = ["aborted"];

                function Miniget(url, options = {}) {
                    var _a;
                    const opts = Object.assign({}, Miniget.defaultOptions, options),
                        stream = new stream_1.PassThrough({
                            highWaterMark: opts.highWaterMark
                        });
                    stream.destroyed = stream.aborted = !1;
                    let activeRequest, activeResponse, activeDecodedStream, redirects = 0,
                        retries = 0,
                        retryTimeout, reconnects = 0,
                        contentLength, acceptRanges = !1,
                        rangeStart = 0,
                        rangeEnd, downloaded = 0;
                    null != (_a = opts.headers) && _a.Range && (_a = /bytes=(\d+)-(\d+)?/.exec("" + opts.headers.Range)) && (rangeStart = parseInt(_a[1], 10), rangeEnd = parseInt(_a[2], 10)), opts.acceptEncoding && (opts.headers = Object.assign({
                        "Accept-Encoding": Object.keys(opts.acceptEncoding).join(", ")
                    }, opts.headers));
                    const downloadHasStarted = () => activeDecodedStream && 0 < downloaded,
                        downloadComplete = () => !acceptRanges || downloaded === contentLength,
                        reconnect = err => {
                            activeDecodedStream = null, retries = 0;
                            var inc = opts.backoff.inc,
                                inc = Math.min(inc, opts.backoff.max);
                            retryTimeout = setTimeout(doDownload, inc), stream.emit("reconnect", reconnects, err)
                        },
                        reconnectIfEndedEarly = err => "HEAD" !== options.method && !downloadComplete() && reconnects++ < opts.maxReconnects && (reconnect(err), !0),
                        retryRequest = retryOptions => {
                            var ms;
                            return !stream.destroyed && (downloadHasStarted() ? reconnectIfEndedEarly(retryOptions.err) : (!retryOptions.err || "ENOTFOUND" === retryOptions.err.message) && retries++ < opts.maxRetries && (ms = retryOptions.retryAfter || Math.min(retries * opts.backoff.inc, opts.backoff.max), retryTimeout = setTimeout(doDownload, ms), stream.emit("retry", retries, retryOptions.err), !0))
                        },
                        forwardEvents = (ee, events) => {
                            for (var event of events) ee.on(event, stream.emit.bind(stream, event))
                        },
                        doDownload = () => {
                            let parsed = {},
                                httpLib;
                            try {
                                var urlObj = "string" == typeof url ? new URL(url) : url;
                                parsed = Object.assign({}, {
                                    host: urlObj.host,
                                    hostname: urlObj.hostname,
                                    path: urlObj.pathname + urlObj.search + urlObj.hash,
                                    port: urlObj.port,
                                    protocol: urlObj.protocol
                                }), urlObj.username && (parsed.auth = urlObj.username + ":" + urlObj.password), httpLib = httpLibs[String(parsed.protocol)]
                            } catch (err) {}
                            if (!httpLib) return void stream.emit("error", new Miniget.MinigetError("Invalid URL: " + url));
                            var end;
                            if (Object.assign(parsed, opts), acceptRanges && 0 < downloaded && (urlObj = downloaded + rangeStart, end = rangeEnd || "", parsed.headers = Object.assign({}, parsed.headers, {
                                    Range: `bytes=${urlObj}-` + end
                                })), opts.transform) {
                                try {
                                    parsed = opts.transform(parsed)
                                } catch (err) {
                                    return void stream.emit("error", err)
                                }
                                if ((!parsed || parsed.protocol) && !(httpLib = httpLibs[String(null === parsed || void 0 === parsed ? void 0 : parsed.protocol)])) return void stream.emit("error", new Miniget.MinigetError("Invalid URL object from `transform` function"))
                            }
                            const onError = err => {
                                    stream.destroyed || stream.readableEnded || (cleanup(), retryRequest({
                                        err: err
                                    }) ? activeRequest.removeListener("close", onRequestClose) : stream.emit("error", err))
                                },
                                onRequestClose = () => {
                                    cleanup(), retryRequest({})
                                },
                                cleanup = () => {
                                    activeRequest.removeListener("close", onRequestClose), null !== activeResponse && void 0 !== activeResponse && activeResponse.removeListener("data", onData), null !== activeDecodedStream && void 0 !== activeDecodedStream && activeDecodedStream.removeListener("end", onEnd)
                                },
                                onData = chunk => {
                                    downloaded += chunk.length
                                },
                                onEnd = () => {
                                    cleanup(), reconnectIfEndedEarly() || stream.end()
                                };
                            (activeRequest = httpLib.request(parsed, res => {
                                if (!stream.destroyed)
                                    if (redirectStatusCodes.has(res.statusCode)) {
                                        if (redirects++ >= opts.maxRedirects) stream.emit("error", new Miniget.MinigetError("Too many redirects"));
                                        else {
                                            var err;
                                            if (!res.headers.location) return err = new Miniget.MinigetError("Redirect status code given with no location", res.statusCode), stream.emit("error", err), void cleanup();
                                            url = res.headers.location, setTimeout(doDownload, 1e3 * parseInt(res.headers["retry-after"] || "0", 10)), stream.emit("redirect", url)
                                        }
                                        cleanup()
                                    } else if (retryStatusCodes.has(res.statusCode)) {
                                    if (!retryRequest({
                                            retryAfter: parseInt(res.headers["retry-after"] || "0", 10)
                                        })) {
                                        let err = new Miniget.MinigetError("Status code: " + res.statusCode, res.statusCode);
                                        stream.emit("error", err)
                                    }
                                    cleanup()
                                } else if (res.statusCode && (res.statusCode < 200 || 400 <= res.statusCode)) {
                                    let err = new Miniget.MinigetError("Status code: " + res.statusCode, res.statusCode);
                                    500 <= res.statusCode ? onError(err) : stream.emit("error", err), void cleanup()
                                } else {
                                    if (activeDecodedStream = res, opts.acceptEncoding && res.headers["content-encoding"])
                                        for (var enc of res.headers["content-encoding"].split(", ").reverse()) {
                                            enc = opts.acceptEncoding[enc];
                                            enc && (activeDecodedStream = activeDecodedStream.pipe(enc())).on("error", onError)
                                        }
                                    contentLength || (contentLength = parseInt("" + res.headers["content-length"], 10), acceptRanges = "bytes" === res.headers["accept-ranges"] && 0 < contentLength && 0 < opts.maxReconnects), res.on("data", onData), activeDecodedStream.on("end", onEnd), activeDecodedStream.pipe(stream, {
                                        end: !acceptRanges
                                    }), activeResponse = res, stream.emit("response", res), res.on("error", onError), forwardEvents(res, responseEvents)
                                }
                            })).on("error", onError), activeRequest.on("close", onRequestClose), forwardEvents(activeRequest, requestEvents), stream.destroyed && streamDestroy(...destroyArgs), stream.emit("request", activeRequest), activeRequest.end()
                        };
                    stream.abort = err => {
                        console.warn("`MinigetStream#abort()` has been deprecated in favor of `MinigetStream#destroy()`"), stream.aborted = !0, stream.emit("abort"), stream.destroy(err)
                    };
                    let destroyArgs;
                    const streamDestroy = err => {
                        activeRequest.destroy(err), null !== activeDecodedStream && void 0 !== activeDecodedStream && activeDecodedStream.unpipe(stream), null !== activeDecodedStream && void 0 !== activeDecodedStream && activeDecodedStream.destroy(), clearTimeout(retryTimeout)
                    };
                    return stream._destroy = (...args) => {
                        stream.destroyed = !0, activeRequest ? streamDestroy(...args) : destroyArgs = args
                    }, stream.text = () => new Promise((resolve, reject) => {
                        let body = "";
                        stream.setEncoding("utf8"), stream.on("data", chunk => body += chunk), stream.on("end", () => resolve(body)), stream.on("error", reject)
                    }), process.nextTick(doDownload), stream
                }
                Miniget.MinigetError = class extends Error {
                    constructor(message, statusCode) {
                        super(message), this.statusCode = statusCode
                    }
                }, Miniget.defaultOptions = {
                    maxRedirects: 10,
                    maxRetries: 2,
                    maxReconnects: 0,
                    backoff: {
                        inc: 100,
                        max: 1e4
                    }
                }, module.exports = Miniget
            }.call(this)
        }.call(this, require("_process"))
    }, {
        _process: 9,
        http: 30,
        https: 6,
        stream: 15
    }],
    63: [function(require, module, exports) {
        ! function(Buffer) {
            ! function() {
                var sax = void 0 === exports ? this.sax = {} : exports;
                sax.parser = function(strict, opt) {
                    return new SAXParser(strict, opt)
                }, sax.SAXParser = SAXParser, sax.SAXStream = SAXStream, sax.createStream = function(strict, opt) {
                    return new SAXStream(strict, opt)
                }, sax.MAX_BUFFER_LENGTH = 65536;
                var Stream, buffers = ["comment", "sgmlDecl", "textNode", "tagName", "doctype", "procInstName", "procInstBody", "entity", "attribName", "attribValue", "cdata", "script"];

                function SAXParser(strict, opt) {
                    if (!(this instanceof SAXParser)) return new SAXParser(strict, opt);
                    ! function(parser) {
                        for (var i = 0, l = buffers.length; i < l; i++) parser[buffers[i]] = ""
                    }(this), this.q = this.c = "", this.bufferCheckPosition = sax.MAX_BUFFER_LENGTH, this.opt = opt || {}, this.opt.lowercase = this.opt.lowercase || this.opt.lowercasetags, this.looseCase = this.opt.lowercase ? "toLowerCase" : "toUpperCase", this.tags = [], this.closed = this.closedRoot = this.sawRoot = !1, this.tag = this.error = null, this.strict = !!strict, this.noscript = !(!strict && !this.opt.noscript), this.state = S.BEGIN, this.strictEntities = this.opt.strictEntities, this.ENTITIES = this.strictEntities ? Object.create(sax.XML_ENTITIES) : Object.create(sax.ENTITIES), this.attribList = [], this.opt.xmlns && (this.ns = Object.create(rootNS)), this.trackPosition = !1 !== this.opt.position, this.trackPosition && (this.position = this.line = this.column = 0), emit(this, "onready")
                }
                sax.EVENTS = ["text", "processinginstruction", "sgmldeclaration", "doctype", "comment", "opentagstart", "attribute", "opentag", "closetag", "opencdata", "cdata", "closecdata", "error", "end", "ready", "script", "opennamespace", "closenamespace"], Object.create || (Object.create = function(o) {
                    function F() {}
                    return F.prototype = o, new F
                }), Object.keys || (Object.keys = function(o) {
                    var i, a = [];
                    for (i in o) o.hasOwnProperty(i) && a.push(i);
                    return a
                }), SAXParser.prototype = {
                    end: function() {
                        end(this)
                    },
                    write: function(chunk) {
                        if (this.error) throw this.error;
                        if (this.closed) return error(this, "Cannot write after close. Assign an onready handler.");
                        if (null === chunk) return end(this);
                        "object" == typeof chunk && (chunk = chunk.toString());
                        var returnState, buffer, i = 0,
                            c = "";
                        for (;;) {
                            if (c = charAt(chunk, i++), !(this.c = c)) break;
                            switch (this.trackPosition && (this.position++, "\n" === c ? (this.line++, this.column = 0) : this.column++), this.state) {
                                case S.BEGIN:
                                    if (this.state = S.BEGIN_WHITESPACE, "\ufeff" === c) continue;
                                    beginWhiteSpace(this, c);
                                    continue;
                                case S.BEGIN_WHITESPACE:
                                    beginWhiteSpace(this, c);
                                    continue;
                                case S.TEXT:
                                    if (this.sawRoot && !this.closedRoot) {
                                        for (var starti = i - 1; c && "<" !== c && "&" !== c;)(c = charAt(chunk, i++)) && this.trackPosition && (this.position++, "\n" === c ? (this.line++, this.column = 0) : this.column++);
                                        this.textNode += chunk.substring(starti, i - 1)
                                    }
                                    "<" !== c || this.sawRoot && this.closedRoot && !this.strict ? (isWhitespace(c) || this.sawRoot && !this.closedRoot || strictFail(this, "Text data outside of root node."), "&" === c ? this.state = S.TEXT_ENTITY : this.textNode += c) : (this.state = S.OPEN_WAKA, this.startTagPosition = this.position);
                                    continue;
                                case S.SCRIPT:
                                    "<" === c ? this.state = S.SCRIPT_ENDING : this.script += c;
                                    continue;
                                case S.SCRIPT_ENDING:
                                    "/" === c ? this.state = S.CLOSE_TAG : (this.script += "<" + c, this.state = S.SCRIPT);
                                    continue;
                                case S.OPEN_WAKA:
                                    "!" === c ? (this.state = S.SGML_DECL, this.sgmlDecl = "") : isWhitespace(c) || (isMatch(nameStart, c) ? (this.state = S.OPEN_TAG, this.tagName = c) : "/" === c ? (this.state = S.CLOSE_TAG, this.tagName = "") : "?" === c ? (this.state = S.PROC_INST, this.procInstName = this.procInstBody = "") : (strictFail(this, "Unencoded <"), this.startTagPosition + 1 < this.position && (starti = this.position - this.startTagPosition, c = new Array(starti).join(" ") + c), this.textNode += "<" + c, this.state = S.TEXT));
                                    continue;
                                case S.SGML_DECL:
                                    (this.sgmlDecl + c).toUpperCase() === CDATA ? (emitNode(this, "onopencdata"), this.state = S.CDATA, this.sgmlDecl = "", this.cdata = "") : this.sgmlDecl + c === "--" ? (this.state = S.COMMENT, this.comment = "", this.sgmlDecl = "") : (this.sgmlDecl + c).toUpperCase() === DOCTYPE ? (this.state = S.DOCTYPE, (this.doctype || this.sawRoot) && strictFail(this, "Inappropriately located doctype declaration"), this.doctype = "", this.sgmlDecl = "") : ">" === c ? (emitNode(this, "onsgmldeclaration", this.sgmlDecl), this.sgmlDecl = "", this.state = S.TEXT) : (isQuote(c) && (this.state = S.SGML_DECL_QUOTED), this.sgmlDecl += c);
                                    continue;
                                case S.SGML_DECL_QUOTED:
                                    c === this.q && (this.state = S.SGML_DECL, this.q = ""), this.sgmlDecl += c;
                                    continue;
                                case S.DOCTYPE:
                                    ">" === c ? (this.state = S.TEXT, emitNode(this, "ondoctype", this.doctype), this.doctype = !0) : (this.doctype += c, "[" === c ? this.state = S.DOCTYPE_DTD : isQuote(c) && (this.state = S.DOCTYPE_QUOTED, this.q = c));
                                    continue;
                                case S.DOCTYPE_QUOTED:
                                    this.doctype += c, c === this.q && (this.q = "", this.state = S.DOCTYPE);
                                    continue;
                                case S.DOCTYPE_DTD:
                                    this.doctype += c, "]" === c ? this.state = S.DOCTYPE : isQuote(c) && (this.state = S.DOCTYPE_DTD_QUOTED, this.q = c);
                                    continue;
                                case S.DOCTYPE_DTD_QUOTED:
                                    this.doctype += c, c === this.q && (this.state = S.DOCTYPE_DTD, this.q = "");
                                    continue;
                                case S.COMMENT:
                                    "-" === c ? this.state = S.COMMENT_ENDING : this.comment += c;
                                    continue;
                                case S.COMMENT_ENDING:
                                    "-" === c ? (this.state = S.COMMENT_ENDED, this.comment = textopts(this.opt, this.comment), this.comment && emitNode(this, "oncomment", this.comment), this.comment = "") : (this.comment += "-" + c, this.state = S.COMMENT);
                                    continue;
                                case S.COMMENT_ENDED:
                                    ">" !== c ? (strictFail(this, "Malformed comment"), this.comment += "--" + c, this.state = S.COMMENT) : this.state = S.TEXT;
                                    continue;
                                case S.CDATA:
                                    "]" === c ? this.state = S.CDATA_ENDING : this.cdata += c;
                                    continue;
                                case S.CDATA_ENDING:
                                    "]" === c ? this.state = S.CDATA_ENDING_2 : (this.cdata += "]" + c, this.state = S.CDATA);
                                    continue;
                                case S.CDATA_ENDING_2:
                                    ">" === c ? (this.cdata && emitNode(this, "oncdata", this.cdata), emitNode(this, "onclosecdata"), this.cdata = "", this.state = S.TEXT) : "]" === c ? this.cdata += "]" : (this.cdata += "]]" + c, this.state = S.CDATA);
                                    continue;
                                case S.PROC_INST:
                                    "?" === c ? this.state = S.PROC_INST_ENDING : isWhitespace(c) ? this.state = S.PROC_INST_BODY : this.procInstName += c;
                                    continue;
                                case S.PROC_INST_BODY:
                                    if (!this.procInstBody && isWhitespace(c)) continue;
                                    "?" === c ? this.state = S.PROC_INST_ENDING : this.procInstBody += c;
                                    continue;
                                case S.PROC_INST_ENDING:
                                    ">" === c ? (emitNode(this, "onprocessinginstruction", {
                                        name: this.procInstName,
                                        body: this.procInstBody
                                    }), this.procInstName = this.procInstBody = "", this.state = S.TEXT) : (this.procInstBody += "?" + c, this.state = S.PROC_INST_BODY);
                                    continue;
                                case S.OPEN_TAG:
                                    isMatch(nameBody, c) ? this.tagName += c : (function(parser) {
                                        parser.strict || (parser.tagName = parser.tagName[parser.looseCase]());
                                        var parent = parser.tags[parser.tags.length - 1] || parser,
                                            tag = parser.tag = {
                                                name: parser.tagName,
                                                attributes: {}
                                            };
                                        parser.opt.xmlns && (tag.ns = parent.ns);
                                        parser.attribList.length = 0, emitNode(parser, "onopentagstart", tag)
                                    }(this), ">" === c ? openTag(this) : "/" === c ? this.state = S.OPEN_TAG_SLASH : (isWhitespace(c) || strictFail(this, "Invalid character in tag name"), this.state = S.ATTRIB));
                                    continue;
                                case S.OPEN_TAG_SLASH:
                                    ">" === c ? (openTag(this, !0), closeTag(this)) : (strictFail(this, "Forward-slash in opening tag not followed by >"), this.state = S.ATTRIB);
                                    continue;
                                case S.ATTRIB:
                                    if (isWhitespace(c)) continue;
                                    ">" === c ? openTag(this) : "/" === c ? this.state = S.OPEN_TAG_SLASH : isMatch(nameStart, c) ? (this.attribName = c, this.attribValue = "", this.state = S.ATTRIB_NAME) : strictFail(this, "Invalid attribute name");
                                    continue;
                                case S.ATTRIB_NAME:
                                    "=" === c ? this.state = S.ATTRIB_VALUE : ">" === c ? (strictFail(this, "Attribute without value"), this.attribValue = this.attribName, attrib(this), openTag(this)) : isWhitespace(c) ? this.state = S.ATTRIB_NAME_SAW_WHITE : isMatch(nameBody, c) ? this.attribName += c : strictFail(this, "Invalid attribute name");
                                    continue;
                                case S.ATTRIB_NAME_SAW_WHITE:
                                    if ("=" === c) this.state = S.ATTRIB_VALUE;
                                    else {
                                        if (isWhitespace(c)) continue;
                                        strictFail(this, "Attribute without value"), this.tag.attributes[this.attribName] = "", this.attribValue = "", emitNode(this, "onattribute", {
                                            name: this.attribName,
                                            value: ""
                                        }), this.attribName = "", ">" === c ? openTag(this) : isMatch(nameStart, c) ? (this.attribName = c, this.state = S.ATTRIB_NAME) : (strictFail(this, "Invalid attribute name"), this.state = S.ATTRIB)
                                    }
                                    continue;
                                case S.ATTRIB_VALUE:
                                    if (isWhitespace(c)) continue;
                                    isQuote(c) ? (this.q = c, this.state = S.ATTRIB_VALUE_QUOTED) : (strictFail(this, "Unquoted attribute value"), this.state = S.ATTRIB_VALUE_UNQUOTED, this.attribValue = c);
                                    continue;
                                case S.ATTRIB_VALUE_QUOTED:
                                    if (c !== this.q) {
                                        "&" === c ? this.state = S.ATTRIB_VALUE_ENTITY_Q : this.attribValue += c;
                                        continue
                                    }
                                    attrib(this), this.q = "", this.state = S.ATTRIB_VALUE_CLOSED;
                                    continue;
                                case S.ATTRIB_VALUE_CLOSED:
                                    isWhitespace(c) ? this.state = S.ATTRIB : ">" === c ? openTag(this) : "/" === c ? this.state = S.OPEN_TAG_SLASH : isMatch(nameStart, c) ? (strictFail(this, "No whitespace between attributes"), this.attribName = c, this.attribValue = "", this.state = S.ATTRIB_NAME) : strictFail(this, "Invalid attribute name");
                                    continue;
                                case S.ATTRIB_VALUE_UNQUOTED:
                                    if (! function(c) {
                                            return ">" === c || isWhitespace(c)
                                        }(c)) {
                                        "&" === c ? this.state = S.ATTRIB_VALUE_ENTITY_U : this.attribValue += c;
                                        continue
                                    }
                                    attrib(this), ">" === c ? openTag(this) : this.state = S.ATTRIB;
                                    continue;
                                case S.CLOSE_TAG:
                                    if (this.tagName) ">" === c ? closeTag(this) : isMatch(nameBody, c) ? this.tagName += c : this.script ? (this.script += "</" + this.tagName, this.tagName = "", this.state = S.SCRIPT) : (isWhitespace(c) || strictFail(this, "Invalid tagname in closing tag"), this.state = S.CLOSE_TAG_SAW_WHITE);
                                    else {
                                        if (isWhitespace(c)) continue;
                                        ! function(regex, c) {
                                            return !isMatch(regex, c)
                                        }(nameStart, c) ? this.tagName = c: this.script ? (this.script += "</" + c, this.state = S.SCRIPT) : strictFail(this, "Invalid tagname in closing tag.")
                                    }
                                    continue;
                                case S.CLOSE_TAG_SAW_WHITE:
                                    if (isWhitespace(c)) continue;
                                    ">" === c ? closeTag(this) : strictFail(this, "Invalid characters in closing tag");
                                    continue;
                                case S.TEXT_ENTITY:
                                case S.ATTRIB_VALUE_ENTITY_Q:
                                case S.ATTRIB_VALUE_ENTITY_U:
                                    switch (this.state) {
                                        case S.TEXT_ENTITY:
                                            returnState = S.TEXT, buffer = "textNode";
                                            break;
                                        case S.ATTRIB_VALUE_ENTITY_Q:
                                            returnState = S.ATTRIB_VALUE_QUOTED, buffer = "attribValue";
                                            break;
                                        case S.ATTRIB_VALUE_ENTITY_U:
                                            returnState = S.ATTRIB_VALUE_UNQUOTED, buffer = "attribValue"
                                    }
                                    ";" === c ? (this[buffer] += function(parser) {
                                        var num, entity = parser.entity,
                                            entityLC = entity.toLowerCase(),
                                            numStr = "";
                                        if (parser.ENTITIES[entity]) return parser.ENTITIES[entity];
                                        if (parser.ENTITIES[entityLC]) return parser.ENTITIES[entityLC];
                                        "#" === (entity = entityLC).charAt(0) && (numStr = "x" === entity.charAt(1) ? (entity = entity.slice(2), (num = parseInt(entity, 16)).toString(16)) : (entity = entity.slice(1), (num = parseInt(entity, 10)).toString(10)));
                                        if (entity = entity.replace(/^0+/, ""), isNaN(num) || numStr.toLowerCase() !== entity) return strictFail(parser, "Invalid character entity"), "&" + parser.entity + ";";
                                        return String.fromCodePoint(num)
                                    }(this), this.entity = "", this.state = returnState) : isMatch(this.entity.length ? entityBody : entityStart, c) ? this.entity += c : (strictFail(this, "Invalid character in entity name"), this[buffer] += "&" + this.entity + c, this.entity = "", this.state = returnState);
                                    continue;
                                default:
                                    throw new Error(this, "Unknown state: " + this.state)
                            }
                        }
                        this.position >= this.bufferCheckPosition && ! function(parser) {
                            for (var maxAllowed = Math.max(sax.MAX_BUFFER_LENGTH, 10), maxActual = 0, i = 0, l = buffers.length; i < l; i++) {
                                var len = parser[buffers[i]].length;
                                if (maxAllowed < len) switch (buffers[i]) {
                                    case "textNode":
                                        closeText(parser);
                                        break;
                                    case "cdata":
                                        emitNode(parser, "oncdata", parser.cdata), parser.cdata = "";
                                        break;
                                    case "script":
                                        emitNode(parser, "onscript", parser.script), parser.script = "";
                                        break;
                                    default:
                                        error(parser, "Max buffer length exceeded: " + buffers[i])
                                }
                                maxActual = Math.max(maxActual, len)
                            }
                            var m = sax.MAX_BUFFER_LENGTH - maxActual;
                            parser.bufferCheckPosition = m + parser.position
                        }(this);
                        return this
                    },
                    resume: function() {
                        return this.error = null, this
                    },
                    close: function() {
                        return this.write(null)
                    },
                    flush: function() {
                        var parser;
                        closeText(parser = this), "" !== parser.cdata && (emitNode(parser, "oncdata", parser.cdata), parser.cdata = ""), "" !== parser.script && (emitNode(parser, "onscript", parser.script), parser.script = "")
                    }
                };
                try {
                    Stream = require("stream").Stream
                } catch (ex) {
                    Stream = function() {}
                }
                var streamWraps = sax.EVENTS.filter(function(ev) {
                    return "error" !== ev && "end" !== ev
                });

                function SAXStream(strict, opt) {
                    if (!(this instanceof SAXStream)) return new SAXStream(strict, opt);
                    Stream.apply(this), this._parser = new SAXParser(strict, opt), this.writable = !0, this.readable = !0;
                    var me = this;
                    this._parser.onend = function() {
                        me.emit("end")
                    }, this._parser.onerror = function(er) {
                        me.emit("error", er), me._parser.error = null
                    }, this._decoder = null, streamWraps.forEach(function(ev) {
                        Object.defineProperty(me, "on" + ev, {
                            get: function() {
                                return me._parser["on" + ev]
                            },
                            set: function(h) {
                                if (!h) return me.removeAllListeners(ev), me._parser["on" + ev] = h;
                                me.on(ev, h)
                            },
                            enumerable: !0,
                            configurable: !1
                        })
                    })
                }(SAXStream.prototype = Object.create(Stream.prototype, {
                    constructor: {
                        value: SAXStream
                    }
                })).write = function(data) {
                    var SD;
                    return "function" == typeof Buffer && "function" == typeof Buffer.isBuffer && Buffer.isBuffer(data) && (this._decoder || (SD = require("string_decoder").StringDecoder, this._decoder = new SD("utf8")), data = this._decoder.write(data)), this._parser.write(data.toString()), this.emit("data", data), !0
                }, SAXStream.prototype.end = function(chunk) {
                    return chunk && chunk.length && this.write(chunk), this._parser.end(), !0
                }, SAXStream.prototype.on = function(ev, handler) {
                    var me = this;
                    return me._parser["on" + ev] || -1 === streamWraps.indexOf(ev) || (me._parser["on" + ev] = function() {
                        var args = 1 === arguments.length ? [arguments[0]] : Array.apply(null, arguments);
                        args.splice(0, 0, ev), me.emit.apply(me, args)
                    }), Stream.prototype.on.call(me, ev, handler)
                };
                var CDATA = "[CDATA[",
                    DOCTYPE = "DOCTYPE",
                    XML_NAMESPACE = "http://www.w3.org/XML/1998/namespace",
                    XMLNS_NAMESPACE = "http://www.w3.org/2000/xmlns/",
                    rootNS = {
                        xml: XML_NAMESPACE,
                        xmlns: XMLNS_NAMESPACE
                    },
                    nameStart = /[:_A-Za-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]/,
                    nameBody = /[:_A-Za-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD\u00B7\u0300-\u036F\u203F-\u2040.\d-]/,
                    entityStart = /[#:_A-Za-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]/,
                    entityBody = /[#:_A-Za-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD\u00B7\u0300-\u036F\u203F-\u2040.\d-]/;

                function isWhitespace(c) {
                    return " " === c || "\n" === c || "\r" === c || "\t" === c
                }

                function isQuote(c) {
                    return '"' === c || "'" === c
                }

                function isMatch(regex, c) {
                    return regex.test(c)
                }
                var s, stringFromCharCode, floor, S = 0;
                for (s in sax.STATE = {
                        BEGIN: S++,
                        BEGIN_WHITESPACE: S++,
                        TEXT: S++,
                        TEXT_ENTITY: S++,
                        OPEN_WAKA: S++,
                        SGML_DECL: S++,
                        SGML_DECL_QUOTED: S++,
                        DOCTYPE: S++,
                        DOCTYPE_QUOTED: S++,
                        DOCTYPE_DTD: S++,
                        DOCTYPE_DTD_QUOTED: S++,
                        COMMENT_STARTING: S++,
                        COMMENT: S++,
                        COMMENT_ENDING: S++,
                        COMMENT_ENDED: S++,
                        CDATA: S++,
                        CDATA_ENDING: S++,
                        CDATA_ENDING_2: S++,
                        PROC_INST: S++,
                        PROC_INST_BODY: S++,
                        PROC_INST_ENDING: S++,
                        OPEN_TAG: S++,
                        OPEN_TAG_SLASH: S++,
                        ATTRIB: S++,
                        ATTRIB_NAME: S++,
                        ATTRIB_NAME_SAW_WHITE: S++,
                        ATTRIB_VALUE: S++,
                        ATTRIB_VALUE_QUOTED: S++,
                        ATTRIB_VALUE_CLOSED: S++,
                        ATTRIB_VALUE_UNQUOTED: S++,
                        ATTRIB_VALUE_ENTITY_Q: S++,
                        ATTRIB_VALUE_ENTITY_U: S++,
                        CLOSE_TAG: S++,
                        CLOSE_TAG_SAW_WHITE: S++,
                        SCRIPT: S++,
                        SCRIPT_ENDING: S++
                    }, sax.XML_ENTITIES = {
                        amp: "&",
                        gt: ">",
                        lt: "<",
                        quot: '"',
                        apos: "'"
                    }, sax.ENTITIES = {
                        amp: "&",
                        gt: ">",
                        lt: "<",
                        quot: '"',
                        apos: "'",
                        AElig: 198,
                        Aacute: 193,
                        Acirc: 194,
                        Agrave: 192,
                        Aring: 197,
                        Atilde: 195,
                        Auml: 196,
                        Ccedil: 199,
                        ETH: 208,
                        Eacute: 201,
                        Ecirc: 202,
                        Egrave: 200,
                        Euml: 203,
                        Iacute: 205,
                        Icirc: 206,
                        Igrave: 204,
                        Iuml: 207,
                        Ntilde: 209,
                        Oacute: 211,
                        Ocirc: 212,
                        Ograve: 210,
                        Oslash: 216,
                        Otilde: 213,
                        Ouml: 214,
                        THORN: 222,
                        Uacute: 218,
                        Ucirc: 219,
                        Ugrave: 217,
                        Uuml: 220,
                        Yacute: 221,
                        aacute: 225,
                        acirc: 226,
                        aelig: 230,
                        agrave: 224,
                        aring: 229,
                        atilde: 227,
                        auml: 228,
                        ccedil: 231,
                        eacute: 233,
                        ecirc: 234,
                        egrave: 232,
                        eth: 240,
                        euml: 235,
                        iacute: 237,
                        icirc: 238,
                        igrave: 236,
                        iuml: 239,
                        ntilde: 241,
                        oacute: 243,
                        ocirc: 244,
                        ograve: 242,
                        oslash: 248,
                        otilde: 245,
                        ouml: 246,
                        szlig: 223,
                        thorn: 254,
                        uacute: 250,
                        ucirc: 251,
                        ugrave: 249,
                        uuml: 252,
                        yacute: 253,
                        yuml: 255,
                        copy: 169,
                        reg: 174,
                        nbsp: 160,
                        iexcl: 161,
                        cent: 162,
                        pound: 163,
                        curren: 164,
                        yen: 165,
                        brvbar: 166,
                        sect: 167,
                        uml: 168,
                        ordf: 170,
                        laquo: 171,
                        not: 172,
                        shy: 173,
                        macr: 175,
                        deg: 176,
                        plusmn: 177,
                        sup1: 185,
                        sup2: 178,
                        sup3: 179,
                        acute: 180,
                        micro: 181,
                        para: 182,
                        middot: 183,
                        cedil: 184,
                        ordm: 186,
                        raquo: 187,
                        frac14: 188,
                        frac12: 189,
                        frac34: 190,
                        iquest: 191,
                        times: 215,
                        divide: 247,
                        OElig: 338,
                        oelig: 339,
                        Scaron: 352,
                        scaron: 353,
                        Yuml: 376,
                        fnof: 402,
                        circ: 710,
                        tilde: 732,
                        Alpha: 913,
                        Beta: 914,
                        Gamma: 915,
                        Delta: 916,
                        Epsilon: 917,
                        Zeta: 918,
                        Eta: 919,
                        Theta: 920,
                        Iota: 921,
                        Kappa: 922,
                        Lambda: 923,
                        Mu: 924,
                        Nu: 925,
                        Xi: 926,
                        Omicron: 927,
                        Pi: 928,
                        Rho: 929,
                        Sigma: 931,
                        Tau: 932,
                        Upsilon: 933,
                        Phi: 934,
                        Chi: 935,
                        Psi: 936,
                        Omega: 937,
                        alpha: 945,
                        beta: 946,
                        gamma: 947,
                        delta: 948,
                        epsilon: 949,
                        zeta: 950,
                        eta: 951,
                        theta: 952,
                        iota: 953,
                        kappa: 954,
                        lambda: 955,
                        mu: 956,
                        nu: 957,
                        xi: 958,
                        omicron: 959,
                        pi: 960,
                        rho: 961,
                        sigmaf: 962,
                        sigma: 963,
                        tau: 964,
                        upsilon: 965,
                        phi: 966,
                        chi: 967,
                        psi: 968,
                        omega: 969,
                        thetasym: 977,
                        upsih: 978,
                        piv: 982,
                        ensp: 8194,
                        emsp: 8195,
                        thinsp: 8201,
                        zwnj: 8204,
                        zwj: 8205,
                        lrm: 8206,
                        rlm: 8207,
                        ndash: 8211,
                        mdash: 8212,
                        lsquo: 8216,
                        rsquo: 8217,
                        sbquo: 8218,
                        ldquo: 8220,
                        rdquo: 8221,
                        bdquo: 8222,
                        dagger: 8224,
                        Dagger: 8225,
                        bull: 8226,
                        hellip: 8230,
                        permil: 8240,
                        prime: 8242,
                        Prime: 8243,
                        lsaquo: 8249,
                        rsaquo: 8250,
                        oline: 8254,
                        frasl: 8260,
                        euro: 8364,
                        image: 8465,
                        weierp: 8472,
                        real: 8476,
                        trade: 8482,
                        alefsym: 8501,
                        larr: 8592,
                        uarr: 8593,
                        rarr: 8594,
                        darr: 8595,
                        harr: 8596,
                        crarr: 8629,
                        lArr: 8656,
                        uArr: 8657,
                        rArr: 8658,
                        dArr: 8659,
                        hArr: 8660,
                        forall: 8704,
                        part: 8706,
                        exist: 8707,
                        empty: 8709,
                        nabla: 8711,
                        isin: 8712,
                        notin: 8713,
                        ni: 8715,
                        prod: 8719,
                        sum: 8721,
                        minus: 8722,
                        lowast: 8727,
                        radic: 8730,
                        prop: 8733,
                        infin: 8734,
                        ang: 8736,
                        and: 8743,
                        or: 8744,
                        cap: 8745,
                        cup: 8746,
                        int: 8747,
                        there4: 8756,
                        sim: 8764,
                        cong: 8773,
                        asymp: 8776,
                        ne: 8800,
                        equiv: 8801,
                        le: 8804,
                        ge: 8805,
                        sub: 8834,
                        sup: 8835,
                        nsub: 8836,
                        sube: 8838,
                        supe: 8839,
                        oplus: 8853,
                        otimes: 8855,
                        perp: 8869,
                        sdot: 8901,
                        lceil: 8968,
                        rceil: 8969,
                        lfloor: 8970,
                        rfloor: 8971,
                        lang: 9001,
                        rang: 9002,
                        loz: 9674,
                        spades: 9824,
                        clubs: 9827,
                        hearts: 9829,
                        diams: 9830
                    }, Object.keys(sax.ENTITIES).forEach(function(key) {
                        var e = sax.ENTITIES[key],
                            e = "number" == typeof e ? String.fromCharCode(e) : e;
                        sax.ENTITIES[key] = e
                    }), sax.STATE) sax.STATE[sax.STATE[s]] = s;

                function emit(parser, event, data) {
                    parser[event] && parser[event](data)
                }

                function emitNode(parser, nodeType, data) {
                    parser.textNode && closeText(parser), emit(parser, nodeType, data)
                }

                function closeText(parser) {
                    parser.textNode = textopts(parser.opt, parser.textNode), parser.textNode && emit(parser, "ontext", parser.textNode), parser.textNode = ""
                }

                function textopts(opt, text) {
                    return opt.trim && (text = text.trim()), text = opt.normalize ? text.replace(/\s+/g, " ") : text
                }

                function error(parser, er) {
                    return closeText(parser), parser.trackPosition && (er += "\nLine: " + parser.line + "\nColumn: " + parser.column + "\nChar: " + parser.c), er = new Error(er), parser.error = er, emit(parser, "onerror", er), parser
                }

                function end(parser) {
                    return parser.sawRoot && !parser.closedRoot && strictFail(parser, "Unclosed root tag"), parser.state !== S.BEGIN && parser.state !== S.BEGIN_WHITESPACE && parser.state !== S.TEXT && error(parser, "Unexpected end"), closeText(parser), parser.c = "", parser.closed = !0, emit(parser, "onend"), SAXParser.call(parser, parser.strict, parser.opt), parser
                }

                function strictFail(parser, message) {
                    if ("object" != typeof parser || !(parser instanceof SAXParser)) throw new Error("bad call to strictFail");
                    parser.strict && error(parser, message)
                }

                function qname(name, attribute) {
                    var qualName = name.indexOf(":") < 0 ? ["", name] : name.split(":"),
                        prefix = qualName[0],
                        qualName = qualName[1];
                    return attribute && "xmlns" === name && (prefix = "xmlns", qualName = ""), {
                        prefix: prefix,
                        local: qualName
                    }
                }

                function attrib(parser) {
                    var qn, prefix, parent;
                    parser.strict || (parser.attribName = parser.attribName[parser.looseCase]()), -1 !== parser.attribList.indexOf(parser.attribName) || parser.tag.attributes.hasOwnProperty(parser.attribName) || (parser.opt.xmlns ? (prefix = (qn = qname(parser.attribName, !0)).prefix, qn = qn.local, "xmlns" === prefix && ("xml" === qn && parser.attribValue !== XML_NAMESPACE ? strictFail(parser, "xml: prefix must be bound to " + XML_NAMESPACE + "\nActual: " + parser.attribValue) : "xmlns" === qn && parser.attribValue !== XMLNS_NAMESPACE ? strictFail(parser, "xmlns: prefix must be bound to " + XMLNS_NAMESPACE + "\nActual: " + parser.attribValue) : (prefix = parser.tag, parent = parser.tags[parser.tags.length - 1] || parser, prefix.ns === parent.ns && (prefix.ns = Object.create(parent.ns)), prefix.ns[qn] = parser.attribValue)), parser.attribList.push([parser.attribName, parser.attribValue])) : (parser.tag.attributes[parser.attribName] = parser.attribValue, emitNode(parser, "onattribute", {
                        name: parser.attribName,
                        value: parser.attribValue
                    }))), parser.attribName = parser.attribValue = ""
                }

                function openTag(parser, selfClosing) {
                    if (parser.opt.xmlns) {
                        var tag = parser.tag,
                            qn = qname(parser.tagName),
                            qn = (tag.prefix = qn.prefix, tag.local = qn.local, tag.uri = tag.ns[qn.prefix] || "", tag.prefix && !tag.uri && (strictFail(parser, "Unbound namespace prefix: " + JSON.stringify(parser.tagName)), tag.uri = qn.prefix), parser.tags[parser.tags.length - 1] || parser);
                        tag.ns && qn.ns !== tag.ns && Object.keys(tag.ns).forEach(function(p) {
                            emitNode(parser, "onopennamespace", {
                                prefix: p,
                                uri: tag.ns[p]
                            })
                        });
                        for (var i = 0, l = parser.attribList.length; i < l; i++) {
                            var nv = parser.attribList[i],
                                name = nv[0],
                                nv = nv[1],
                                qualName = qname(name, !0),
                                prefix = qualName.prefix,
                                qualName = qualName.local,
                                uri = "" !== prefix && tag.ns[prefix] || "",
                                nv = {
                                    name: name,
                                    value: nv,
                                    prefix: prefix,
                                    local: qualName,
                                    uri: uri
                                };
                            prefix && "xmlns" !== prefix && !uri && (strictFail(parser, "Unbound namespace prefix: " + JSON.stringify(prefix)), nv.uri = prefix), parser.tag.attributes[name] = nv, emitNode(parser, "onattribute", nv)
                        }
                        parser.attribList.length = 0
                    }
                    parser.tag.isSelfClosing = !!selfClosing, parser.sawRoot = !0, parser.tags.push(parser.tag), emitNode(parser, "onopentag", parser.tag), selfClosing || (parser.noscript || "script" !== parser.tagName.toLowerCase() ? parser.state = S.TEXT : parser.state = S.SCRIPT, parser.tag = null, parser.tagName = ""), parser.attribName = parser.attribValue = "", parser.attribList.length = 0
                }

                function closeTag(parser) {
                    if (parser.tagName) {
                        if (parser.script) {
                            if ("script" !== parser.tagName) return parser.script += "</" + parser.tagName + ">", parser.tagName = "", void(parser.state = S.SCRIPT);
                            emitNode(parser, "onscript", parser.script), parser.script = ""
                        }
                        for (var t = parser.tags.length, tagName = parser.tagName, closeTo = tagName = parser.strict ? tagName : tagName[parser.looseCase](); t-- && parser.tags[t].name !== closeTo;) strictFail(parser, "Unexpected close tag");
                        if (t < 0) strictFail(parser, "Unmatched closing tag: " + parser.tagName), parser.textNode += "</" + parser.tagName + ">";
                        else {
                            parser.tagName = tagName;
                            for (var s = parser.tags.length; s-- > t;) {
                                var i, tag = parser.tag = parser.tags.pop();
                                parser.tagName = parser.tag.name, emitNode(parser, "onclosetag", parser.tagName);
                                for (i in tag.ns) i, tag.ns[i];
                                var parent = parser.tags[parser.tags.length - 1] || parser;
                                parser.opt.xmlns && tag.ns !== parent.ns && Object.keys(tag.ns).forEach(function(p) {
                                    var n = tag.ns[p];
                                    emitNode(parser, "onclosenamespace", {
                                        prefix: p,
                                        uri: n
                                    })
                                })
                            }
                            0 === t && (parser.closedRoot = !0), parser.tagName = parser.attribValue = parser.attribName = "", parser.attribList.length = 0
                        }
                    } else strictFail(parser, "Weird empty close tag."), parser.textNode += "</>";
                    parser.state = S.TEXT
                }

                function beginWhiteSpace(parser, c) {
                    "<" === c ? (parser.state = S.OPEN_WAKA, parser.startTagPosition = parser.position) : isWhitespace(c) || (strictFail(parser, "Non-whitespace before first tag."), parser.textNode = c, parser.state = S.TEXT)
                }

                function charAt(chunk, i) {
                    var result = "";
                    return result = i < chunk.length ? chunk.charAt(i) : result
                }

                function fromCodePoint() {
                    var codeUnits = [],
                        index = -1,
                        length = arguments.length;
                    if (!length) return "";
                    for (var result = ""; ++index < length;) {
                        var codePoint = Number(arguments[index]);
                        if (!isFinite(codePoint) || codePoint < 0 || 1114111 < codePoint || floor(codePoint) !== codePoint) throw RangeError("Invalid code point: " + codePoint);
                        codePoint <= 65535 ? codeUnits.push(codePoint) : codeUnits.push(55296 + ((codePoint -= 65536) >> 10), codePoint % 1024 + 56320), (index + 1 === length || 16384 < codeUnits.length) && (result += stringFromCharCode.apply(null, codeUnits), codeUnits.length = 0)
                    }
                    return result
                }
                S = sax.STATE, String.fromCodePoint || (stringFromCharCode = String.fromCharCode, floor = Math.floor, Object.defineProperty ? Object.defineProperty(String, "fromCodePoint", {
                    value: fromCodePoint,
                    configurable: !0,
                    writable: !0
                }) : String.fromCodePoint = fromCodePoint)
            }.call(this)
        }.call(this, require("buffer").Buffer)
    }, {
        buffer: 3,
        stream: 15,
        string_decoder: 49
    }],
    64: [function(require, module, exports) {
        const setTimeout = require("timers")["setTimeout"];
        module.exports = class extends Map {
            constructor(timeout = 1e3) {
                super(), this.timeout = timeout
            }
            set(key, value) {
                this.has(key) && clearTimeout(super.get(key).tid), super.set(key, {
                    tid: setTimeout(this.delete.bind(this, key), this.timeout).unref(),
                    value: value
                })
            }
            get(key) {
                key = super.get(key);
                return key ? key.value : null
            }
            getOrSet(key, fn) {
                if (this.has(key)) return this.get(key); {
                    let value = fn();
                    return this.set(key, value), (async () => {
                        try {
                            await value
                        } catch (err) {
                            this.delete(key)
                        }
                    })(), value
                }
            }
            delete(key) {
                var entry = super.get(key);
                entry && (clearTimeout(entry.tid), super.delete(key))
            }
            clear() {
                for (var entry of this.values()) clearTimeout(entry.tid);
                super.clear()
            }
        }
    }, {
        timers: 50
    }],
    65: [function(require, module, exports) {
        const utils = require("./utils"),
            FORMATS = require("./formats"),
            audioEncodingRanks = ["mp4a", "mp3", "vorbis", "aac", "opus", "flac"],
            videoEncodingRanks = ["mp4v", "avc1", "Sorenson H.283", "MPEG-4 Visual", "VP8", "VP9", "H.264"],
            getVideoBitrate = format => format.bitrate || 0,
            getVideoEncodingRank = format => videoEncodingRanks.findIndex(enc => format.codecs && format.codecs.includes(enc)),
            getAudioBitrate = format => format.audioBitrate || 0,
            getAudioEncodingRank = format => audioEncodingRanks.findIndex(enc => format.codecs && format.codecs.includes(enc)),
            sortFormatsBy = (a, b, sortBy) => {
                let res = 0;
                for (var fn of sortBy)
                    if (0 !== (res = fn(b) - fn(a))) break;
                return res
            },
            sortFormatsByVideo = (a, b) => sortFormatsBy(a, b, [format => parseInt(format.qualityLabel), getVideoBitrate, getVideoEncodingRank]),
            sortFormatsByAudio = (a, b) => sortFormatsBy(a, b, [getAudioBitrate, getAudioEncodingRank]),
            getFormatByQuality = (exports.sortFormats = (a, b) => sortFormatsBy(a, b, [format => +!!format.isHLS, format => +!!format.isDashMPD, format => +(0 < format.contentLength), format => +(format.hasVideo && format.hasAudio), format => +format.hasVideo, format => parseInt(format.qualityLabel) || 0, getVideoBitrate, getAudioBitrate, getVideoEncodingRank, getAudioEncodingRank]), exports.chooseFormat = (formats, options) => {
                if ("object" == typeof options.format) {
                    if (options.format.url) return options.format;
                    throw Error("Invalid format given, did you use `ytdl.getInfo()`?")
                }(formats = options.filter ? exports.filterFormats(formats, options.filter) : formats).some(fmt => fmt.isHLS) && (formats = formats.filter(fmt => fmt.isHLS || !fmt.isLive));
                let format;
                var quality = options.quality || "highest";
                switch (quality) {
                    case "highest":
                        format = formats[0];
                        break;
                    case "lowest":
                        format = formats[formats.length - 1];
                        break;
                    case "highestaudio": {
                        (formats = exports.filterFormats(formats, "audio")).sort(sortFormatsByAudio);
                        const bestAudioFormat = formats[0],
                            worstVideoQuality = (formats = formats.filter(f => 0 === sortFormatsByAudio(bestAudioFormat, f))).map(f => parseInt(f.qualityLabel) || 0).sort((a, b) => a - b)[0];
                        format = formats.find(f => (parseInt(f.qualityLabel) || 0) === worstVideoQuality);
                        break
                    }
                    case "lowestaudio":
                        (formats = exports.filterFormats(formats, "audio")).sort(sortFormatsByAudio), format = formats[formats.length - 1];
                        break;
                    case "highestvideo": {
                        (formats = exports.filterFormats(formats, "video")).sort(sortFormatsByVideo);
                        const bestVideoFormat = formats[0],
                            worstAudioQuality = (formats = formats.filter(f => 0 === sortFormatsByVideo(bestVideoFormat, f))).map(f => f.audioBitrate || 0).sort((a, b) => a - b)[0];
                        format = formats.find(f => (f.audioBitrate || 0) === worstAudioQuality);
                        break
                    }
                    case "lowestvideo":
                        (formats = exports.filterFormats(formats, "video")).sort(sortFormatsByVideo), format = formats[formats.length - 1];
                        break;
                    default:
                        format = getFormatByQuality(quality, formats)
                }
                if (format) return format;
                throw Error("No such format found: " + quality)
            }, (quality, formats) => {
                let getFormat = itag => formats.find(format => "" + format.itag == "" + itag);
                return Array.isArray(quality) ? getFormat(quality.find(q => getFormat(q))) : getFormat(quality)
            });
        exports.filterFormats = (formats, filter) => {
            let fn;
            switch (filter) {
                case "videoandaudio":
                case "audioandvideo":
                    fn = format => format.hasVideo && format.hasAudio;
                    break;
                case "video":
                    fn = format => format.hasVideo;
                    break;
                case "videoonly":
                    fn = format => format.hasVideo && !format.hasAudio;
                    break;
                case "audio":
                    fn = format => format.hasAudio;
                    break;
                case "audioonly":
                    fn = format => !format.hasVideo && format.hasAudio;
                    break;
                default:
                    if ("function" != typeof filter) throw TypeError(`Given filter (${filter}) is not supported`);
                    fn = filter
            }
            return formats.filter(format => !!format.url && fn(format))
        }, exports.addFormatMeta = format => ((format = Object.assign({}, FORMATS[format.itag], format)).hasVideo = !!format.qualityLabel, format.hasAudio = !!format.audioBitrate, format.container = format.mimeType ? format.mimeType.split(";")[0].split("/")[1] : null, format.codecs = format.mimeType ? utils.between(format.mimeType, 'codecs="', '"') : null, format.videoCodec = format.hasVideo && format.codecs ? format.codecs.split(", ")[0] : null, format.audioCodec = format.hasAudio && format.codecs ? format.codecs.split(", ").slice(-1)[0] : null, format.isLive = /\bsource[/=]yt_live_broadcast\b/.test(format.url), format.isHLS = /\/manifest\/hls_(variant|playlist)\//.test(format.url), format.isDashMPD = /\/manifest\/dash\//.test(format.url), format)
    }, {
        "./formats": 66,
        "./utils": 72
    }],
    66: [function(require, module, exports) {
        module.exports = {
            5: {
                mimeType: 'video/flv; codecs="Sorenson H.283, mp3"',
                qualityLabel: "240p",
                bitrate: 25e4,
                audioBitrate: 64
            },
            6: {
                mimeType: 'video/flv; codecs="Sorenson H.263, mp3"',
                qualityLabel: "270p",
                bitrate: 8e5,
                audioBitrate: 64
            },
            13: {
                mimeType: 'video/3gp; codecs="MPEG-4 Visual, aac"',
                qualityLabel: null,
                bitrate: 5e5,
                audioBitrate: null
            },
            17: {
                mimeType: 'video/3gp; codecs="MPEG-4 Visual, aac"',
                qualityLabel: "144p",
                bitrate: 5e4,
                audioBitrate: 24
            },
            18: {
                mimeType: 'video/mp4; codecs="H.264, aac"',
                qualityLabel: "360p",
                bitrate: 5e5,
                audioBitrate: 96
            },
            22: {
                mimeType: 'video/mp4; codecs="H.264, aac"',
                qualityLabel: "720p",
                bitrate: 2e6,
                audioBitrate: 192
            },
            34: {
                mimeType: 'video/flv; codecs="H.264, aac"',
                qualityLabel: "360p",
                bitrate: 5e5,
                audioBitrate: 128
            },
            35: {
                mimeType: 'video/flv; codecs="H.264, aac"',
                qualityLabel: "480p",
                bitrate: 8e5,
                audioBitrate: 128
            },
            36: {
                mimeType: 'video/3gp; codecs="MPEG-4 Visual, aac"',
                qualityLabel: "240p",
                bitrate: 175e3,
                audioBitrate: 32
            },
            37: {
                mimeType: 'video/mp4; codecs="H.264, aac"',
                qualityLabel: "1080p",
                bitrate: 3e6,
                audioBitrate: 192
            },
            38: {
                mimeType: 'video/mp4; codecs="H.264, aac"',
                qualityLabel: "3072p",
                bitrate: 35e5,
                audioBitrate: 192
            },
            43: {
                mimeType: 'video/webm; codecs="VP8, vorbis"',
                qualityLabel: "360p",
                bitrate: 5e5,
                audioBitrate: 128
            },
            44: {
                mimeType: 'video/webm; codecs="VP8, vorbis"',
                qualityLabel: "480p",
                bitrate: 1e6,
                audioBitrate: 128
            },
            45: {
                mimeType: 'video/webm; codecs="VP8, vorbis"',
                qualityLabel: "720p",
                bitrate: 2e6,
                audioBitrate: 192
            },
            46: {
                mimeType: 'audio/webm; codecs="vp8, vorbis"',
                qualityLabel: "1080p",
                bitrate: null,
                audioBitrate: 192
            },
            82: {
                mimeType: 'video/mp4; codecs="H.264, aac"',
                qualityLabel: "360p",
                bitrate: 5e5,
                audioBitrate: 96
            },
            83: {
                mimeType: 'video/mp4; codecs="H.264, aac"',
                qualityLabel: "240p",
                bitrate: 5e5,
                audioBitrate: 96
            },
            84: {
                mimeType: 'video/mp4; codecs="H.264, aac"',
                qualityLabel: "720p",
                bitrate: 2e6,
                audioBitrate: 192
            },
            85: {
                mimeType: 'video/mp4; codecs="H.264, aac"',
                qualityLabel: "1080p",
                bitrate: 3e6,
                audioBitrate: 192
            },
            91: {
                mimeType: 'video/ts; codecs="H.264, aac"',
                qualityLabel: "144p",
                bitrate: 1e5,
                audioBitrate: 48
            },
            92: {
                mimeType: 'video/ts; codecs="H.264, aac"',
                qualityLabel: "240p",
                bitrate: 15e4,
                audioBitrate: 48
            },
            93: {
                mimeType: 'video/ts; codecs="H.264, aac"',
                qualityLabel: "360p",
                bitrate: 5e5,
                audioBitrate: 128
            },
            94: {
                mimeType: 'video/ts; codecs="H.264, aac"',
                qualityLabel: "480p",
                bitrate: 8e5,
                audioBitrate: 128
            },
            95: {
                mimeType: 'video/ts; codecs="H.264, aac"',
                qualityLabel: "720p",
                bitrate: 15e5,
                audioBitrate: 256
            },
            96: {
                mimeType: 'video/ts; codecs="H.264, aac"',
                qualityLabel: "1080p",
                bitrate: 25e5,
                audioBitrate: 256
            },
            100: {
                mimeType: 'audio/webm; codecs="VP8, vorbis"',
                qualityLabel: "360p",
                bitrate: null,
                audioBitrate: 128
            },
            101: {
                mimeType: 'audio/webm; codecs="VP8, vorbis"',
                qualityLabel: "360p",
                bitrate: null,
                audioBitrate: 192
            },
            102: {
                mimeType: 'audio/webm; codecs="VP8, vorbis"',
                qualityLabel: "720p",
                bitrate: null,
                audioBitrate: 192
            },
            120: {
                mimeType: 'video/flv; codecs="H.264, aac"',
                qualityLabel: "720p",
                bitrate: 2e6,
                audioBitrate: 128
            },
            127: {
                mimeType: 'audio/ts; codecs="aac"',
                qualityLabel: null,
                bitrate: null,
                audioBitrate: 96
            },
            128: {
                mimeType: 'audio/ts; codecs="aac"',
                qualityLabel: null,
                bitrate: null,
                audioBitrate: 96
            },
            132: {
                mimeType: 'video/ts; codecs="H.264, aac"',
                qualityLabel: "240p",
                bitrate: 15e4,
                audioBitrate: 48
            },
            133: {
                mimeType: 'video/mp4; codecs="H.264"',
                qualityLabel: "240p",
                bitrate: 2e5,
                audioBitrate: null
            },
            134: {
                mimeType: 'video/mp4; codecs="H.264"',
                qualityLabel: "360p",
                bitrate: 3e5,
                audioBitrate: null
            },
            135: {
                mimeType: 'video/mp4; codecs="H.264"',
                qualityLabel: "480p",
                bitrate: 5e5,
                audioBitrate: null
            },
            136: {
                mimeType: 'video/mp4; codecs="H.264"',
                qualityLabel: "720p",
                bitrate: 1e6,
                audioBitrate: null
            },
            137: {
                mimeType: 'video/mp4; codecs="H.264"',
                qualityLabel: "1080p",
                bitrate: 25e5,
                audioBitrate: null
            },
            138: {
                mimeType: 'video/mp4; codecs="H.264"',
                qualityLabel: "4320p",
                bitrate: 135e5,
                audioBitrate: null
            },
            139: {
                mimeType: 'audio/mp4; codecs="aac"',
                qualityLabel: null,
                bitrate: null,
                audioBitrate: 48
            },
            140: {
                mimeType: 'audio/m4a; codecs="aac"',
                qualityLabel: null,
                bitrate: null,
                audioBitrate: 128
            },
            141: {
                mimeType: 'audio/mp4; codecs="aac"',
                qualityLabel: null,
                bitrate: null,
                audioBitrate: 256
            },
            151: {
                mimeType: 'video/ts; codecs="H.264, aac"',
                qualityLabel: "720p",
                bitrate: 5e4,
                audioBitrate: 24
            },
            160: {
                mimeType: 'video/mp4; codecs="H.264"',
                qualityLabel: "144p",
                bitrate: 1e5,
                audioBitrate: null
            },
            171: {
                mimeType: 'audio/webm; codecs="vorbis"',
                qualityLabel: null,
                bitrate: null,
                audioBitrate: 128
            },
            172: {
                mimeType: 'audio/webm; codecs="vorbis"',
                qualityLabel: null,
                bitrate: null,
                audioBitrate: 192
            },
            242: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: "240p",
                bitrate: 1e5,
                audioBitrate: null
            },
            243: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: "360p",
                bitrate: 25e4,
                audioBitrate: null
            },
            244: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: "480p",
                bitrate: 5e5,
                audioBitrate: null
            },
            247: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: "720p",
                bitrate: 7e5,
                audioBitrate: null
            },
            248: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: "1080p",
                bitrate: 15e5,
                audioBitrate: null
            },
            249: {
                mimeType: 'audio/webm; codecs="opus"',
                qualityLabel: null,
                bitrate: null,
                audioBitrate: 48
            },
            250: {
                mimeType: 'audio/webm; codecs="opus"',
                qualityLabel: null,
                bitrate: null,
                audioBitrate: 64
            },
            251: {
                mimeType: 'audio/webm; codecs="opus"',
                qualityLabel: null,
                bitrate: null,
                audioBitrate: 160
            },
            264: {
                mimeType: 'video/mp4; codecs="H.264"',
                qualityLabel: "1440p",
                bitrate: 4e6,
                audioBitrate: null
            },
            266: {
                mimeType: 'video/mp4; codecs="H.264"',
                qualityLabel: "2160p",
                bitrate: 125e5,
                audioBitrate: null
            },
            271: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: "1440p",
                bitrate: 9e6,
                audioBitrate: null
            },
            272: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: "4320p",
                bitrate: 2e7,
                audioBitrate: null
            },
            278: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: "144p 30fps",
                bitrate: 8e4,
                audioBitrate: null
            },
            298: {
                mimeType: 'video/mp4; codecs="H.264"',
                qualityLabel: "720p",
                bitrate: 3e6,
                audioBitrate: null
            },
            299: {
                mimeType: 'video/mp4; codecs="H.264"',
                qualityLabel: "1080p",
                bitrate: 55e5,
                audioBitrate: null
            },
            300: {
                mimeType: 'video/ts; codecs="H.264, aac"',
                qualityLabel: "720p",
                bitrate: 1318e3,
                audioBitrate: 48
            },
            302: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: "720p HFR",
                bitrate: 25e5,
                audioBitrate: null
            },
            303: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: "1080p HFR",
                bitrate: 5e6,
                audioBitrate: null
            },
            308: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: "1440p HFR",
                bitrate: 1e7,
                audioBitrate: null
            },
            313: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: "2160p",
                bitrate: 13e6,
                audioBitrate: null
            },
            315: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: "2160p HFR",
                bitrate: 2e7,
                audioBitrate: null
            },
            330: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: "144p HDR, HFR",
                bitrate: 8e4,
                audioBitrate: null
            },
            331: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: "240p HDR, HFR",
                bitrate: 1e5,
                audioBitrate: null
            },
            332: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: "360p HDR, HFR",
                bitrate: 25e4,
                audioBitrate: null
            },
            333: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: "240p HDR, HFR",
                bitrate: 5e5,
                audioBitrate: null
            },
            334: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: "720p HDR, HFR",
                bitrate: 1e6,
                audioBitrate: null
            },
            335: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: "1080p HDR, HFR",
                bitrate: 15e5,
                audioBitrate: null
            },
            336: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: "1440p HDR, HFR",
                bitrate: 5e6,
                audioBitrate: null
            },
            337: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: "2160p HDR, HFR",
                bitrate: 12e6,
                audioBitrate: null
            }
        }
    }, {}],
    67: [function(require, module, exports) {
        ! function(setImmediate) {
            ! function() {
                const PassThrough = require("stream").PassThrough;
                var getInfo = require("./info");
                const utils = require("./utils"),
                    formatUtils = require("./format-utils");
                var urlUtils = require("./url-utils"),
                    sig = require("./sig");
                const miniget = require("miniget"),
                    m3u8stream = require("m3u8stream"),
                    parseTimestamp = require("m3u8stream")["parseTimestamp"],
                    ytdl = (link, options) => {
                        const stream = createStream(options);
                        return ytdl.getInfo(link, options).then(info => {
                            downloadFromInfoCallback(stream, info, options)
                        }, stream.emit.bind(stream, "error")), stream
                    },
                    createStream = ((module.exports = ytdl).getBasicInfo = getInfo.getBasicInfo, ytdl.getInfo = getInfo.getInfo, ytdl.chooseFormat = formatUtils.chooseFormat, ytdl.filterFormats = formatUtils.filterFormats, ytdl.validateID = urlUtils.validateID, ytdl.validateURL = urlUtils.validateURL, ytdl.getURLVideoID = urlUtils.getURLVideoID, ytdl.getVideoID = urlUtils.getVideoID, ytdl.cache = {
                        sig: sig.cache,
                        info: getInfo.cache,
                        watch: getInfo.watchPageCache,
                        cookie: getInfo.cookieCache
                    }, ytdl.version = require("../package.json").version, options => {
                        const stream = new PassThrough({
                            highWaterMark: options && options.highWaterMark || 524288
                        });
                        return stream._destroy = () => {
                            stream.destroyed = !0
                        }, stream
                    }),
                    pipeAndSetEvents = (req, stream, end) => {
                        ["abort", "request", "response", "error", "redirect", "retry", "reconnect"].forEach(event => {
                            req.prependListener(event, stream.emit.bind(stream, event))
                        }), req.pipe(stream, {
                            end: end
                        })
                    },
                    downloadFromInfoCallback = (stream, info, options) => {
                        options = options || {};
                        var err = utils.playError(info.player_response, ["UNPLAYABLE", "LIVE_STREAM_OFFLINE", "LOGIN_REQUIRED"]);
                        if (err) stream.emit("error", err);
                        else if (info.formats.length) {
                            let format;
                            try {
                                format = formatUtils.chooseFormat(info.formats, options)
                            } catch (e) {
                                return void stream.emit("error", e)
                            }
                            if (stream.emit("info", info, format), !stream.destroyed) {
                                let contentLength, downloaded = 0;
                                const ondata = chunk => {
                                        downloaded += chunk.length, stream.emit("progress", chunk.length, downloaded, contentLength)
                                    },
                                    dlChunkSize = (options.IPv6Block && (options.requestOptions = Object.assign({}, options.requestOptions, {
                                        family: 6,
                                        localAddress: utils.getRandomIPv6(options.IPv6Block)
                                    })), options.dlChunkSize || 10485760);
                                let req, shouldEnd = !0;
                                if (format.isHLS || format.isDashMPD)(req = m3u8stream(format.url, {
                                    chunkReadahead: +info.live_chunk_readahead,
                                    begin: options.begin || format.isLive && Date.now(),
                                    liveBuffer: options.liveBuffer,
                                    requestOptions: options.requestOptions,
                                    parser: format.isDashMPD ? "dash-mpd" : "m3u8",
                                    id: format.itag
                                })).on("progress", (segment, totalSegments) => {
                                    stream.emit("progress", segment.size, segment.num, totalSegments)
                                }), pipeAndSetEvents(req, stream, shouldEnd);
                                else {
                                    const requestOptions = Object.assign({}, options.requestOptions, {
                                        maxReconnects: 6,
                                        maxRetries: 3,
                                        backoff: {
                                            inc: 500,
                                            max: 1e4
                                        }
                                    });
                                    if (!(0 === dlChunkSize || format.hasAudio && format.hasVideo)) {
                                        let start = options.range && options.range.start || 0,
                                            end = start + dlChunkSize;
                                        const rangeEnd = options.range && options.range.end,
                                            getNextChunk = (contentLength = options.range ? (rangeEnd ? rangeEnd + 1 : parseInt(format.contentLength)) - start : parseInt(format.contentLength), () => {
                                                !rangeEnd && end >= contentLength && (end = 0), rangeEnd && end > rangeEnd && (end = rangeEnd), shouldEnd = !end || end === rangeEnd, requestOptions.headers = Object.assign({}, requestOptions.headers, {
                                                    Range: `bytes=${start}-` + (end || "")
                                                }), (req = miniget(format.url, requestOptions)).on("data", ondata), req.on("end", () => {
                                                    stream.destroyed || end && end !== rangeEnd && (start = end + 1, end += dlChunkSize, getNextChunk())
                                                }), pipeAndSetEvents(req, stream, shouldEnd)
                                            });
                                        getNextChunk()
                                    } else options.begin && (format.url += "&begin=" + parseTimestamp(options.begin)), options.range && (options.range.start || options.range.end) && (requestOptions.headers = Object.assign({}, requestOptions.headers, {
                                        Range: `bytes=${options.range.start||"0"}-` + (options.range.end || "")
                                    })), (req = miniget(format.url, requestOptions)).on("response", res => {
                                        stream.destroyed || (contentLength = contentLength || parseInt(res.headers["content-length"]))
                                    }), req.on("data", ondata), pipeAndSetEvents(req, stream, shouldEnd)
                                }
                                stream._destroy = () => {
                                    stream.destroyed = !0, req.destroy(), req.end()
                                }
                            }
                        } else stream.emit("error", Error("This video is unavailable"))
                    };
                ytdl.downloadFromInfo = (info, options) => {
                    const stream = createStream(options);
                    if (info.full) return setImmediate(() => {
                        downloadFromInfoCallback(stream, info, options)
                    }), stream;
                    throw Error("Cannot use `ytdl.downloadFromInfo()` when called with info from `ytdl.getBasicInfo()`")
                }
            }.call(this)
        }.call(this, require("timers").setImmediate)
    }, {
        "../package.json": 73,
        "./format-utils": 65,
        "./info": 69,
        "./sig": 70,
        "./url-utils": 71,
        "./utils": 72,
        m3u8stream: 58,
        miniget: 62,
        stream: 15,
        timers: 50
    }],
    68: [function(require, module, exports) {
        const utils = require("./utils"),
            qs = require("querystring"),
            parseTimestamp = require("m3u8stream")["parseTimestamp"],
            BASE_URL = "https://www.youtube.com/watch?v=",
            TITLE_TO_CATEGORY = {
                song: {
                    name: "Music",
                    url: "https://music.youtube.com/"
                }
            },
            getText = obj => obj ? obj.runs ? obj.runs[0].text : obj.simpleText : null,
            isVerified = (exports.getMedia = info => {
                var media = {};
                let results = [];
                try {
                    results = info.response.contents.twoColumnWatchNextResults.results.results.contents
                } catch (err) {}
                var row, richMetadataRenderer, info = results.find(v => v.videoSecondaryInfoRenderer);
                if (!info) return {};
                try {
                    for (row of (info.metadataRowContainer || info.videoSecondaryInfoRenderer.metadataRowContainer).metadataRowContainerRenderer.rows)
                        if (row.metadataRowRenderer) {
                            var title = getText(row.metadataRowRenderer.title).toLowerCase(),
                                contents = row.metadataRowRenderer.contents[0],
                                runs = (media[title] = getText(contents), contents.runs);
                            runs && runs[0].navigationEndpoint && (media[title + "_url"] = new URL(runs[0].navigationEndpoint.commandMetadata.webCommandMetadata.url, BASE_URL).toString()), title in TITLE_TO_CATEGORY && (media.category = TITLE_TO_CATEGORY[title].name, media.category_url = TITLE_TO_CATEGORY[title].url)
                        } else if (row.richMetadataRowRenderer) {
                        let contents = row.richMetadataRowRenderer.contents;
                        for ({
                                richMetadataRenderer
                            }
                            of contents.filter(meta => "RICH_METADATA_RENDERER_STYLE_BOX_ART" === meta.richMetadataRenderer.style)) {
                            var meta = richMetadataRenderer,
                                type = (media.year = getText(meta.subtitle), getText(meta.callToAction).split(" ")[1]);
                            media[type] = getText(meta.title), media[type + "_url"] = new URL(meta.endpoint.commandMetadata.webCommandMetadata.url, BASE_URL).toString(), media.thumbnails = meta.thumbnail.thumbnails
                        }
                        for (let {
                                richMetadataRenderer
                            }
                            of contents.filter(meta => "RICH_METADATA_RENDERER_STYLE_TOPIC" === meta.richMetadataRenderer.style)) {
                            let meta = richMetadataRenderer;
                            media.category = getText(meta.title), media.category_url = new URL(meta.endpoint.commandMetadata.webCommandMetadata.url, BASE_URL).toString()
                        }
                    }
                } catch (err) {}
                return media
            }, badges => !(!badges || !badges.find(b => "Verified" === b.metadataBadgeRenderer.tooltip))),
            parseRelatedVideo = (exports.getAuthor = info => {
                let channelId, thumbnails = [],
                    subscriberCount, verified = !1;
                try {
                    var videoOwnerRenderer = info.response.contents.twoColumnWatchNextResults.results.results.contents.find(v2 => v2.videoSecondaryInfoRenderer && v2.videoSecondaryInfoRenderer.owner && v2.videoSecondaryInfoRenderer.owner.videoOwnerRenderer).videoSecondaryInfoRenderer.owner.videoOwnerRenderer;
                    channelId = videoOwnerRenderer.navigationEndpoint.browseEndpoint.browseId, thumbnails = videoOwnerRenderer.thumbnail.thumbnails.map(thumbnail => (thumbnail.url = new URL(thumbnail.url, BASE_URL).toString(), thumbnail)), subscriberCount = utils.parseAbbreviatedNumber(getText(videoOwnerRenderer.subscriberCountText)), verified = isVerified(videoOwnerRenderer.badges)
                } catch (err) {}
                try {
                    var videoDetails = info.player_response.microformat && info.player_response.microformat.playerMicroformatRenderer,
                        id = videoDetails && videoDetails.channelId || channelId || info.player_response.videoDetails.channelId,
                        author = {
                            id: id,
                            name: videoDetails ? videoDetails.ownerChannelName : info.player_response.videoDetails.author,
                            user: videoDetails ? videoDetails.ownerProfileUrl.split("/").slice(-1)[0] : null,
                            channel_url: "https://www.youtube.com/channel/" + id,
                            external_channel_url: videoDetails ? "https://www.youtube.com/channel/" + videoDetails.externalChannelId : "",
                            user_url: videoDetails ? new URL(videoDetails.ownerProfileUrl, BASE_URL).toString() : "",
                            thumbnails: thumbnails,
                            verified: verified,
                            subscriber_count: subscriberCount
                        };
                    return thumbnails.length && utils.deprecate(author, "avatar", author.thumbnails[0].url, "author.avatar", "author.thumbnails[0].url"), author
                } catch (err) {
                    return {}
                }
            }, (details, rvsParams) => {
                if (details) try {
                    let viewCount = getText(details.viewCountText),
                        shortViewCount = getText(details.shortViewCountText);
                    var rvsDetails = rvsParams.find(elem => elem.id === details.videoId),
                        browseEndpoint = (/^\d/.test(shortViewCount) || (shortViewCount = rvsDetails && rvsDetails.short_view_count_text || ""), viewCount = (/^\d/.test(viewCount) ? viewCount : shortViewCount).split(" ")[0], details.shortBylineText.runs[0].navigationEndpoint.browseEndpoint),
                        channelId = browseEndpoint.browseId,
                        name = getText(details.shortBylineText),
                        user = (browseEndpoint.canonicalBaseUrl || "").split("/").slice(-1)[0];
                    let video = {
                        id: details.videoId,
                        title: getText(details.title),
                        published: getText(details.publishedTimeText),
                        author: {
                            id: channelId,
                            name: name,
                            user: user,
                            channel_url: "https://www.youtube.com/channel/" + channelId,
                            user_url: "https://www.youtube.com/user/" + user,
                            thumbnails: details.channelThumbnail.thumbnails.map(thumbnail => (thumbnail.url = new URL(thumbnail.url, BASE_URL).toString(), thumbnail)),
                            verified: isVerified(details.ownerBadges),
                            [Symbol.toPrimitive]() {
                                return console.warn("`relatedVideo.author` will be removed in a near future release, use `relatedVideo.author.name` instead."), video.author.name
                            }
                        },
                        short_view_count_text: shortViewCount.split(" ")[0],
                        view_count: viewCount.replace(/,/g, ""),
                        length_seconds: details.lengthText ? Math.floor(parseTimestamp(getText(details.lengthText)) / 1e3) : rvsParams && "" + rvsParams.length_seconds,
                        thumbnails: details.thumbnail.thumbnails,
                        richThumbnails: details.richThumbnail ? details.richThumbnail.movingThumbnailRenderer.movingThumbnailDetails.thumbnails : [],
                        isLive: !(!details.badges || !details.badges.find(b => "LIVE NOW" === b.metadataBadgeRenderer.label))
                    };
                    return utils.deprecate(video, "author_thumbnail", video.author.thumbnails[0].url, "relatedVideo.author_thumbnail", "relatedVideo.author.thumbnails[0].url"), utils.deprecate(video, "ucid", video.author.id, "relatedVideo.ucid", "relatedVideo.author.id"), utils.deprecate(video, "video_thumbnail", video.thumbnails[0].url, "relatedVideo.video_thumbnail", "relatedVideo.thumbnails[0].url"), video
                } catch (err) {}
            });
        exports.getRelatedVideos = info => {
            let rvsParams = [],
                secondaryResults = [];
            try {
                rvsParams = info.response.webWatchNextResponseExtensionData.relatedVideoArgs.split(",").map(e => qs.parse(e))
            } catch (err) {}
            try {
                secondaryResults = info.response.contents.twoColumnWatchNextResults.secondaryResults.secondaryResults.results
            } catch (err) {
                return []
            }
            var result, videos = [];
            for (result of secondaryResults || []) {
                var details = result.compactVideoRenderer;
                if (details) {
                    details = parseRelatedVideo(details, rvsParams);
                    details && videos.push(details)
                } else {
                    details = result.compactAutoplayRenderer || result.itemSectionRenderer;
                    if (details && Array.isArray(details.contents))
                        for (var content of details.contents) {
                            let video = parseRelatedVideo(content.compactVideoRenderer, rvsParams);
                            video && videos.push(video)
                        }
                }
            }
            return videos
        }, exports.getLikes = info => {
            try {
                var like = info.response.contents.twoColumnWatchNextResults.results.results.contents.find(r => r.videoPrimaryInfoRenderer).videoPrimaryInfoRenderer.videoActions.menuRenderer.topLevelButtons.find(b => b.toggleButtonRenderer && "LIKE" === b.toggleButtonRenderer.defaultIcon.iconType);
                return parseInt(like.toggleButtonRenderer.defaultText.accessibility.accessibilityData.label.replace(/\D+/g, ""))
            } catch (err) {
                return null
            }
        }, exports.getDislikes = info => {
            try {
                var dislike = info.response.contents.twoColumnWatchNextResults.results.results.contents.find(r => r.videoPrimaryInfoRenderer).videoPrimaryInfoRenderer.videoActions.menuRenderer.topLevelButtons.find(b => b.toggleButtonRenderer && "DISLIKE" === b.toggleButtonRenderer.defaultIcon.iconType);
                return parseInt(dislike.toggleButtonRenderer.defaultText.accessibility.accessibilityData.label.replace(/\D+/g, ""))
            } catch (err) {
                return null
            }
        }, exports.cleanVideoDetails = (videoDetails, info) => (videoDetails.thumbnails = videoDetails.thumbnail.thumbnails, delete videoDetails.thumbnail, utils.deprecate(videoDetails, "thumbnail", {
            thumbnails: videoDetails.thumbnails
        }, "videoDetails.thumbnail.thumbnails", "videoDetails.thumbnails"), videoDetails.description = videoDetails.shortDescription || getText(videoDetails.description), delete videoDetails.shortDescription, utils.deprecate(videoDetails, "shortDescription", videoDetails.description, "videoDetails.shortDescription", "videoDetails.description"), videoDetails.lengthSeconds = info.player_response.microformat && info.player_response.microformat.playerMicroformatRenderer.lengthSeconds || info.player_response.videoDetails.lengthSeconds, videoDetails), exports.getStoryboards = info => {
            info = info.player_response.storyboards && info.player_response.storyboards.playerStoryboardSpecRenderer && info.player_response.storyboards.playerStoryboardSpecRenderer.spec && info.player_response.storyboards.playerStoryboardSpecRenderer.spec.split("|");
            if (!info) return [];
            const url = new URL(info.shift());
            return info.map((part, i) => {
                var [part, thumbnailHeight, thumbnailCount, columns, rows, interval, nameReplacement, sigh] = part.split("#"), sigh = (url.searchParams.set("sigh", sigh), thumbnailCount = parseInt(thumbnailCount, 10), columns = parseInt(columns, 10), rows = parseInt(rows, 10), Math.ceil(thumbnailCount / (columns * rows)));
                return {
                    templateUrl: url.toString().replace("$L", i).replace("$N", nameReplacement),
                    thumbnailWidth: parseInt(part, 10),
                    thumbnailHeight: parseInt(thumbnailHeight, 10),
                    thumbnailCount: thumbnailCount,
                    interval: parseInt(interval, 10),
                    columns: columns,
                    rows: rows,
                    storyboardCount: sigh
                }
            })
        }, exports.getChapters = info => {
            info = info.response && info.response.playerOverlays && info.response.playerOverlays.playerOverlayRenderer, info = info && info.decoratedPlayerBarRenderer && info.decoratedPlayerBarRenderer.decoratedPlayerBarRenderer && info.decoratedPlayerBarRenderer.decoratedPlayerBarRenderer.playerBar, info = info && info.multiMarkersPlayerBarRenderer && info.multiMarkersPlayerBarRenderer.markersMap, info = Array.isArray(info) && info.find(m => m.value && Array.isArray(m.value.chapters));
            return info ? info.value.chapters.map(chapter => ({
                title: getText(chapter.chapterRenderer.title),
                start_time: chapter.chapterRenderer.timeRangeStartMillis / 1e3
            })) : []
        }
    }, {
        "./utils": 72,
        m3u8stream: 58,
        querystring: 13
    }],
    69: [function(require, module, exports) {
        const querystring = require("querystring"),
            sax = require("sax"),
            miniget = require("miniget"),
            utils = require("./utils"),
            setTimeout = require("timers")["setTimeout"],
            formatUtils = require("./format-utils"),
            urlUtils = require("./url-utils"),
            extras = require("./info-extras"),
            sig = require("./sig");
        require = require("./cache");
        const BASE_URL = "https://www.youtube.com/watch?v=";
        exports.cache = new require, exports.cookieCache = new require(864e5), exports.watchPageCache = new require;
        let cver = "2.20210622.10.00";
        class UnrecoverableError extends Error {}
        const AGE_RESTRICTED_URLS = ["support.google.com/youtube/?p=age_restrictions", "youtube.com/t/community_guidelines"],
            privateVideoError = (exports.getBasicInfo = async (id, options) => {
                options.IPv6Block && (options.requestOptions = Object.assign({}, options.requestOptions, {
                    family: 6,
                    localAddress: utils.getRandomIPv6(options.IPv6Block)
                }));
                var retryOptions = Object.assign({}, miniget.defaultOptions, options.requestOptions),
                    options = (options.requestOptions = Object.assign({}, options.requestOptions, {}), options.requestOptions.headers = Object.assign({}, {
                        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.101 Safari/537.36"
                    }, options.requestOptions.headers), await pipeline([id, options], info => {
                        var playErr = utils.playError(info.player_response, ["ERROR"], UnrecoverableError),
                            privateErr = privateVideoError(info.player_response);
                        if (playErr || privateErr) throw playErr || privateErr;
                        return info && info.player_response && (info.player_response.streamingData || isRental(info.player_response) || isNotYetBroadcasted(info.player_response))
                    }, retryOptions, [getWatchHTMLPage, getWatchJSONPage, getVideoInfoPage]));
                Object.assign(options, {
                    formats: parseFormats(options.player_response),
                    related_videos: extras.getRelatedVideos(options)
                });
                const media = extras.getMedia(options);
                retryOptions = {
                    author: extras.getAuthor(options),
                    media: media,
                    likes: extras.getLikes(options),
                    dislikes: extras.getDislikes(options),
                    age_restricted: !(!media || !AGE_RESTRICTED_URLS.some(url => Object.values(media).some(v => "string" == typeof v && v.includes(url)))),
                    video_url: BASE_URL + id,
                    storyboards: extras.getStoryboards(options),
                    chapters: extras.getChapters(options)
                };
                return options.videoDetails = extras.cleanVideoDetails(Object.assign({}, options.player_response && options.player_response.microformat && options.player_response.microformat.playerMicroformatRenderer, options.player_response && options.player_response.videoDetails, retryOptions), options), options
            }, player_response => {
                player_response = player_response && player_response.playabilityStatus;
                return player_response && "LOGIN_REQUIRED" === player_response.status && player_response.messages && player_response.messages.filter(m => /This is a private video/.test(m)).length ? new UnrecoverableError(player_response.reason || player_response.messages && player_response.messages[0]) : null
            }),
            isRental = player_response => {
                player_response = player_response.playabilityStatus;
                return player_response && "UNPLAYABLE" === player_response.status && player_response.errorScreen && player_response.errorScreen.playerLegacyDesktopYpcOfferRenderer
            },
            isNotYetBroadcasted = player_response => {
                player_response = player_response.playabilityStatus;
                return player_response && "LIVE_STREAM_OFFLINE" === player_response.status
            },
            getWatchHTMLURL = (id, options) => BASE_URL + id + "&hl=" + (options.lang || "en"),
            getWatchHTMLPageBody = (id, options) => {
                const url = getWatchHTMLURL(id, options);
                return exports.watchPageCache.getOrSet(url, () => utils.exposedMiniget(url, options).text())
            },
            getHTML5player = body => {
                body = /<script\s+src="([^"]+)"(?:\s+type="text\/javascript")?\s+name="player_ias\/base"\s*>|"jsUrl":"([^"]+)"/.exec(body);
                return body ? body[1] || body[2] : null
            },
            pipeline = async (args, validate, retryOptions, endpoints) => {
                let info;
                for (var func of endpoints) try {
                    var newInfo = await retryFunc(func, args.concat([info]), retryOptions);
                    if (newInfo.player_response && (newInfo.player_response.videoDetails = assign(info && info.player_response && info.player_response.videoDetails, newInfo.player_response.videoDetails), newInfo.player_response = assign(info && info.player_response, newInfo.player_response)), validate(info = assign(info, newInfo), !1)) break
                } catch (err) {
                    if (err instanceof UnrecoverableError || func === endpoints[endpoints.length - 1]) throw err
                }
                return info
            }, assign = (target, source) => {
                if (!target || !source) return target || source;
                for (var [key, value] of Object.entries(source)) null !== value && void 0 !== value && (target[key] = value);
                return target
            }, retryFunc = async (func, args, options) => {
                let currentTry = 0,
                    result;
                for (; currentTry <= options.maxRetries;) try {
                    result = await func(...args);
                    break
                } catch (err) {
                    if (err instanceof UnrecoverableError || err instanceof miniget.MinigetError && err.statusCode < 500 || currentTry >= options.maxRetries) throw err;
                    let wait = Math.min(++currentTry * options.backoff.inc, options.backoff.max);
                    await new Promise(resolve => setTimeout(resolve, wait))
                }
                return result
            }, jsonClosingChars = /^[)\]}'\s]+/, parseJSON = (source, varName, json) => {
                if (!json || "object" == typeof json) return json;
                try {
                    return json = json.replace(jsonClosingChars, ""), JSON.parse(json)
                } catch (err) {
                    throw Error(`Error parsing ${varName} in ${source}: ` + err.message)
                }
            }, findJSON = (source, varName, body, left, right, prependJSON) => {
                body = utils.between(body, left, right);
                if (body) return parseJSON(source, varName, utils.cutAfterJS("" + prependJSON + body));
                throw Error(`Could not find ${varName} in ` + source)
            }, findPlayerResponse = (source, info) => {
                info = info && (info.args && info.args.player_response || info.player_response || info.playerResponse || info.embedded_player_response);
                return parseJSON(source, "player_response", info)
            }, getWatchJSONPage = async (id, options) => {
                const reqOptions = Object.assign({
                    headers: {}
                }, options.requestOptions);
                var cookie = reqOptions.headers.Cookie || reqOptions.headers.cookie,
                    setIdentityToken = (reqOptions.headers = Object.assign({
                        "x-youtube-client-name": "1",
                        "x-youtube-client-version": cver,
                        "x-youtube-identity-token": exports.cookieCache.get(cookie || "browser") || ""
                    }, reqOptions.headers), async (key, throwIfNotFound) => {
                        reqOptions.headers["x-youtube-identity-token"] || (reqOptions.headers["x-youtube-identity-token"] = await ((id, options, key, throwIfNotFound) => exports.cookieCache.getOrSet(key, async () => {
                            var match = (await getWatchHTMLPageBody(id, options)).match(/(["'])ID_TOKEN\1[:,]\s?"([^"]+)"/);
                            if (!match && throwIfNotFound) throw new UnrecoverableError("Cookie header used in request, but unable to find YouTube identity token");
                            return match && match[2]
                        }))(id, options, key, throwIfNotFound))
                    }),
                    cookie = (cookie && await setIdentityToken(cookie, !0), ((id, options) => getWatchHTMLURL(id, options) + "&pbj=1")(id, options)),
                    cookie = await utils.exposedMiniget(cookie, options, reqOptions).text(),
                    cookie = parseJSON("watch.json", "body", cookie);
                if ("now" === cookie.reload && await setIdentityToken("browser", !1), "now" !== cookie.reload && Array.isArray(cookie)) return (setIdentityToken = cookie.reduce((part, curr) => Object.assign(curr, part), {})).player_response = findPlayerResponse("watch.json", setIdentityToken), setIdentityToken.html5player = setIdentityToken.player && setIdentityToken.player.assets && setIdentityToken.player.assets.js, setIdentityToken;
                throw Error("Unable to retrieve video metadata in watch.json")
            }, getWatchHTMLPage = async (id, options) => {
                id = await getWatchHTMLPageBody(id, options), options = {
                    page: "watch"
                };
                try {
                    cver = utils.between(id, '{"key":"cver","value":"', '"}'), options.player_response = findJSON("watch.html", "player_response", id, /\bytInitialPlayerResponse\s*=\s*\{/i, "<\/script>", "{")
                } catch (err) {
                    var args = findJSON("watch.html", "player_response", id, /\bytplayer\.config\s*=\s*{/, "<\/script>", "{");
                    options.player_response = findPlayerResponse("watch.html", args)
                }
                return options.response = findJSON("watch.html", "response", id, /\bytInitialData("\])?\s*=\s*\{/i, "<\/script>", "{"), options.html5player = getHTML5player(id), options
            }, getVideoInfoPage = async (id, options) => {
                var url = new URL("https://www.youtube.com/get_video_info"),
                    id = (url.searchParams.set("video_id", id), url.searchParams.set("c", "TVHTML5"), url.searchParams.set("cver", "7" + cver.substr(1)), url.searchParams.set("eurl", "https://youtube.googleapis.com/v/" + id), url.searchParams.set("ps", "default"), url.searchParams.set("gl", "US"), url.searchParams.set("hl", options.lang || "en"), url.searchParams.set("html5", "1"), await utils.exposedMiniget(url.toString(), options).text()),
                    url = querystring.parse(id);
                return url.player_response = findPlayerResponse("get_video_info", url), url
            }, parseFormats = player_response => {
                let formats = [];
                return formats = player_response && player_response.streamingData ? formats.concat(player_response.streamingData.formats || []).concat(player_response.streamingData.adaptiveFormats || []) : formats
            }, getDashManifest = (exports.getInfo = async (id, options) => {
                var info = await exports.getBasicInfo(id, options),
                    hasManifest = info.player_response && info.player_response.streamingData && (info.player_response.streamingData.dashManifestUrl || info.player_response.streamingData.hlsManifestUrl),
                    funcs = [];
                if (info.formats.length) {
                    if (info.html5player = info.html5player || getHTML5player(await getWatchHTMLPageBody(id, options)) || getHTML5player(await ((id, options) => {
                            id = "https://www.youtube.com/embed/" + id + "?hl=" + (options.lang || "en");
                            return utils.exposedMiniget(id, options).text()
                        })(id, options)), !info.html5player) throw Error("Unable to find html5player file");
                    var id = new URL(info.html5player, BASE_URL).toString();
                    funcs.push(sig.decipherFormats(info.formats, id, options))
                }
                if (hasManifest && info.player_response.streamingData.dashManifestUrl && (id = info.player_response.streamingData.dashManifestUrl, funcs.push(getDashManifest(id, options))), hasManifest && info.player_response.streamingData.hlsManifestUrl) {
                    let url = info.player_response.streamingData.hlsManifestUrl;
                    funcs.push(getM3U8(url, options))
                }
                id = await Promise.all(funcs);
                return info.formats = Object.values(Object.assign({}, ...id)), info.formats = info.formats.map(formatUtils.addFormatMeta), info.formats.sort(formatUtils.sortFormats), info.full = !0, info
            }, (url, options) => new Promise((resolve, reject) => {
                let formats = {};
                const parser = sax.parser(!1);
                parser.onerror = reject;
                let adaptationSet;
                parser.onopentag = node => {
                    var itag;
                    "ADAPTATIONSET" === node.name ? adaptationSet = node.attributes : "REPRESENTATION" === node.name && (itag = parseInt(node.attributes.ID), isNaN(itag) || (formats[url] = Object.assign({
                        itag: itag,
                        url: url,
                        bitrate: parseInt(node.attributes.BANDWIDTH),
                        mimeType: `${adaptationSet.MIMETYPE}; codecs="${node.attributes.CODECS}"`
                    }, node.attributes.HEIGHT ? {
                        width: parseInt(node.attributes.WIDTH),
                        height: parseInt(node.attributes.HEIGHT),
                        fps: parseInt(node.attributes.FRAMERATE)
                    } : {
                        audioSampleRate: node.attributes.AUDIOSAMPLINGRATE
                    })))
                }, parser.onend = () => {
                    resolve(formats)
                };
                var req = utils.exposedMiniget(new URL(url, BASE_URL).toString(), options);
                req.setEncoding("utf8"), req.on("error", reject), req.on("data", chunk => {
                    parser.write(chunk)
                }), req.on("end", parser.close.bind(parser))
            })), getM3U8 = async (url, options) => {
                url = new URL(url, BASE_URL);
                url = await utils.exposedMiniget(url.toString(), options).text();
                let formats = {};
                return url.split("\n").filter(line => /^https?:\/\//.test(line)).forEach(line => {
                    var itag = parseInt(line.match(/\/itag\/(\d+)\//)[1]);
                    formats[line] = {
                        itag: itag,
                        url: line
                    }
                }), formats
            };
        for (let funcName of ["getBasicInfo", "getInfo"]) {
            const func = exports[funcName];
            exports[funcName] = async (link, options = {}) => {
                utils.checkForUpdates();
                let id = await urlUtils.getVideoID(link);
                link = [funcName, id, options.lang].join("-");
                return exports.cache.getOrSet(link, () => func(id, options))
            }
        }
        exports.validateID = urlUtils.validateID, exports.validateURL = urlUtils.validateURL, exports.getURLVideoID = urlUtils.getURLVideoID, exports.getVideoID = urlUtils.getVideoID
    }, {
        "./cache": 64,
        "./format-utils": 65,
        "./info-extras": 68,
        "./sig": 70,
        "./url-utils": 71,
        "./utils": 72,
        miniget: 62,
        querystring: 13,
        sax: 63,
        timers: 50
    }],
    70: [function(require, module, exports) {
        const querystring = require("querystring");
        var Cache = require("./cache");
        const utils = require("./utils"),
            vm = require("vm");
        exports.cache = new Cache, exports.getFunctions = (html5playerfile, options) => exports.cache.getOrSet(html5playerfile, async () => {
            var body = await utils.exposedMiniget(html5playerfile, options).text(),
                body = exports.extractFunctions(body);
            if (body && body.length) return exports.cache.set(html5playerfile, body), body;
            throw Error("Could not extract functions")
        }), exports.extractFunctions = body => {
            const functions = [];
            var ndx, functionStart, functionName;
            return (functionName = utils.between(body, 'a.set("alr","yes");c&&(c=', "(decodeURIC")) && functionName.length && 0 <= (ndx = body.indexOf(functionStart = functionName + "=function(a)")) && (ndx = body.slice(ndx + functionStart.length), functionStart = (caller => {
                var functionStart, ndx, caller = utils.between(caller, 'a=a.split("");', ".");
                return !caller || (ndx = body.indexOf(functionStart = `var ${caller}={`)) < 0 ? "" : (ndx = body.slice(ndx + functionStart.length - 1), `var ${caller}=` + utils.cutAfterJS(ndx))
            })(functionStart = "var " + functionStart + utils.cutAfterJS(ndx)) + `;${functionStart};${functionName}(sig);`, functions.push(functionStart)), (() => {
                let functionName = utils.between(body, '&&(b=a.get("n"))&&(b=', "(b)");
                var ndx, functionStart;
                (functionName = functionName.includes("[") ? utils.between(body, functionName.split("[")[0] + "=[", "]") : functionName) && functionName.length && (functionStart = functionName + "=function(a)", 0 <= (ndx = body.indexOf(functionStart))) && (ndx = body.slice(ndx + functionStart.length), functionStart = `var ${functionStart}${utils.cutAfterJS(ndx)};${functionName}(ncode);`, functions.push(functionStart))
            })(), functions
        }, exports.setDownloadURL = (format, decipherScript, nTransformScript) => {
            var ncode = url => {
                    var components = new URL(decodeURIComponent(url)),
                        n = components.searchParams.get("n");
                    return n && nTransformScript ? (components.searchParams.set("n", nTransformScript.runInNewContext({
                        ncode: n
                    })), components.toString()) : url
                },
                cipher = !format.url,
                url = format.url || format.signatureCipher || format.cipher;
            format.url = ncode(cipher ? (url => {
                var components, url = querystring.parse(url);
                return url.s && decipherScript ? ((components = new URL(decodeURIComponent(url.url))).searchParams.set(url.sp || "signature", decipherScript.runInNewContext({
                    sig: decodeURIComponent(url.s)
                })), components.toString()) : url.url
            })(url) : url), delete format.signatureCipher, delete format.cipher
        }, exports.decipherFormats = async (formats, html5player, options) => {
            let decipheredFormats = {};
            html5player = await exports.getFunctions(html5player, options);
            const decipherScript = html5player.length ? new vm.Script(html5player[0]) : null,
                nTransformScript = 1 < html5player.length ? new vm.Script(html5player[1]) : null;
            return formats.forEach(format => {
                exports.setDownloadURL(format, decipherScript, nTransformScript), decipheredFormats[format.url] = format
            }), decipheredFormats
        }
    }, {
        "./cache": 64,
        "./utils": 72,
        querystring: 13,
        vm: 54
    }],
    71: [function(require, module, exports) {
        const validQueryDomains = new Set(["youtube.com", "www.youtube.com", "m.youtube.com", "music.youtube.com", "gaming.youtube.com"]),
            validPathDomains = /^https?:\/\/(youtu\.be\/|(www\.)?youtube\.com\/(embed|v|shorts)\/)/,
            urlRegex = (exports.getURLVideoID = link => {
                var parsed = new URL(link.trim());
                let id = parsed.searchParams.get("v");
                if (validPathDomains.test(link.trim()) && !id) {
                    var paths = parsed.pathname.split("/");
                    id = "youtu.be" === parsed.host ? paths[1] : paths[2]
                } else if (parsed.hostname && !validQueryDomains.has(parsed.hostname)) throw Error("Not a YouTube domain");
                if (!id) throw Error(`No video id found: "${link}"`);
                if (id = id.substring(0, 11), exports.validateID(id)) return id;
                throw TypeError(`Video id (${id}) does not match expected ` + `format (${idRegex.toString()})`)
            }, /^https?:\/\//),
            idRegex = (exports.getVideoID = str => {
                if (exports.validateID(str)) return str;
                if (urlRegex.test(str.trim())) return exports.getURLVideoID(str);
                throw Error("No video id found: " + str)
            }, /^[a-zA-Z0-9-_]{11}$/);
        exports.validateID = id => idRegex.test(id.trim()), exports.validateURL = string => {
            try {
                return exports.getURLVideoID(string), !0
            } catch (e) {
                return !1
            }
        }
    }, {}],
    72: [function(require, module, exports) {
        ! function(process) {
            ! function() {
                const miniget = require("miniget"),
                    ESCAPING_SEQUENZES = (exports.between = (haystack, left, right) => {
                        let pos;
                        if (left instanceof RegExp) {
                            var match = haystack.match(left);
                            if (!match) return "";
                            pos = match.index + match[0].length
                        } else {
                            if (-1 === (pos = haystack.indexOf(left))) return "";
                            pos += left.length
                        }
                        return haystack = haystack.slice(pos), -1 === (pos = haystack.indexOf(right)) ? "" : haystack.slice(0, pos)
                    }, exports.parseAbbreviatedNumber = string => {
                        var multi, string = string.replace(",", ".").replace(" ", "").match(/([\d,.]+)([MK]?)/);
                        return string ? ([, string, multi] = string, string = parseFloat(string), Math.round("M" === multi ? 1e6 * string : "K" === multi ? 1e3 * string : string)) : null
                    }, [{
                        start: '"',
                        end: '"'
                    }, {
                        start: "'",
                        end: "'"
                    }, {
                        start: "`",
                        end: "`"
                    }, {
                        start: "/",
                        end: "/",
                        startPrefix: /(^|[[{:;,])\s?$/
                    }]),
                    pkg = (exports.cutAfterJS = mixedJson => {
                        let open, close;
                        if ("[" === mixedJson[0] ? (open = "[", close = "]") : "{" === mixedJson[0] && (open = "{", close = "}"), !open) throw new Error("Can't cut unsupported JSON (need to begin with [ or { ) but got: " + mixedJson[0]);
                        let isEscapedObject = null,
                            isEscaped = !1,
                            counter = 0,
                            i;
                        for (i = 0; i < mixedJson.length; i++)
                            if (isEscaped || null === isEscapedObject || mixedJson[i] !== isEscapedObject.end) {
                                if (!isEscaped && null === isEscapedObject) {
                                    for (const escaped of ESCAPING_SEQUENZES)
                                        if (mixedJson[i] === escaped.start && (!escaped.startPrefix || mixedJson.substring(i - 10, i).match(escaped.startPrefix))) {
                                            isEscapedObject = escaped;
                                            break
                                        } if (null !== isEscapedObject) continue
                                }
                                if (isEscaped = "\\" === mixedJson[i] && !isEscaped, null === isEscapedObject && (mixedJson[i] === open ? counter++ : mixedJson[i] === close && counter--, 0 === counter)) return mixedJson.substring(0, i + 1)
                            } else isEscapedObject = null;
                        throw Error("Can't cut unsupported JSON (no matching closing bracket found)")
                    }, exports.playError = (player_response, statuses, ErrorType = Error) => {
                        player_response = player_response && player_response.playabilityStatus;
                        return player_response && statuses.includes(player_response.status) ? new ErrorType(player_response.reason || player_response.messages && player_response.messages[0]) : null
                    }, exports.exposedMiniget = (url, options = {}, requestOptionsOverwrite) => {
                        url = miniget(url, requestOptionsOverwrite || options.requestOptions);
                        return "function" == typeof options.requestCallback && options.requestCallback(url), url
                    }, exports.deprecate = (obj, prop, value, oldPath, newPath) => {
                        Object.defineProperty(obj, prop, {
                            get: () => (console.warn(`\`${oldPath}\` will be removed in a near future release, ` + `use \`${newPath}\` instead.`), value)
                        })
                    }, require("../package.json")),
                    IPV6_REGEX = (exports.lastUpdateCheck = 0, exports.checkForUpdates = () => !process.env.YTDL_NO_UPDATE && !pkg.version.startsWith("0.0.0-") && 432e5 <= Date.now() - exports.lastUpdateCheck ? (exports.lastUpdateCheck = Date.now(), miniget("https://api.github.com/repos/fent/node-ytdl-core/releases/latest", {
                        headers: {
                            "User-Agent": "ytdl-core"
                        }
                    }).text().then(response => {
                        JSON.parse(response).tag_name !== "v" + pkg.version && console.warn('[33mWARNING:[0m ytdl-core is out of date! Update with "npm install ytdl-core@latest".')
                    }, err => {
                        console.warn("Error checking for updates:", err.message), console.warn("You can disable this check by setting the `YTDL_NO_UPDATE` env variable.")
                    })) : null, exports.getRandomIPv6 = ip => {
                        if (!isIPv6(ip)) throw Error("Invalid IPv6 format");
                        var [ip, rawMask] = ip.split("/");
                        let base10Mask = parseInt(rawMask);
                        if (!base10Mask || 128 < base10Mask || base10Mask < 24) throw Error("Invalid IPv6 subnet");
                        const base10addr = normalizeIP(ip);
                        return new Array(8).fill(1).map(() => Math.floor(65535 * Math.random())).map((randomItem, idx) => {
                            var staticBits = Math.min(base10Mask, 16),
                                staticBits = (base10Mask -= staticBits, 65535 - (2 ** (16 - staticBits) - 1));
                            return (base10addr[idx] & staticBits) + (randomItem & (65535 ^ staticBits))
                        }).map(x => x.toString("16")).join(":")
                    }, /^(([0-9a-f]{1,4}:)(:[0-9a-f]{1,4}){1,6}|([0-9a-f]{1,4}:){1,2}(:[0-9a-f]{1,4}){1,5}|([0-9a-f]{1,4}:){1,3}(:[0-9a-f]{1,4}){1,4}|([0-9a-f]{1,4}:){1,4}(:[0-9a-f]{1,4}){1,3}|([0-9a-f]{1,4}:){1,5}(:[0-9a-f]{1,4}){1,2}|([0-9a-f]{1,4}:){1,6}(:[0-9a-f]{1,4})|([0-9a-f]{1,4}:){1,7}(([0-9a-f]{1,4})|:))\/(1[0-1]\d|12[0-8]|\d{1,2})$/),
                    isIPv6 = exports.isIPv6 = ip => IPV6_REGEX.test(ip),
                    normalizeIP = exports.normalizeIP = ip => {
                        var ip = ip.split("::").map(x => x.split(":")),
                            partStart = ip[0] || [],
                            partEnd = ip[1] || [],
                            fullIP = (partEnd.reverse(), new Array(8).fill(0));
                        for (let i = 0; i < Math.min(partStart.length, 8); i++) fullIP[i] = parseInt(partStart[i], 16) || 0;
                        for (let i = 0; i < Math.min(partEnd.length, 8); i++) fullIP[7 - i] = parseInt(partEnd[i], 16) || 0;
                        return fullIP
                    }
            }.call(this)
        }.call(this, require("_process"))
    }, {
        "../package.json": 73,
        _process: 9,
        miniget: 62
    }],
    73: [function(require, module, exports) {
        module.exports = {
            name: "ytdl-core",
            description: "YouTube video downloader in pure javascript.",
            keywords: ["youtube", "video", "download"],
            version: "4.11.2",
            repository: {
                type: "git",
                url: "git://github.com/fent/node-ytdl-core.git"
            },
            author: "fent <fentbox@gmail.com> (https://github.com/fent)",
            contributors: ["Tobias Kutscha (https://github.com/TimeForANinja)", "Andrew Kelley (https://github.com/andrewrk)", "Mauricio Allende (https://github.com/mallendeo)", "Rodrigo Altamirano (https://github.com/raltamirano)", "Jim Buck (https://github.com/JimmyBoh)", "Paweł Ruciński (https://github.com/Roki100)", "Alexander Paolini (https://github.com/Million900o)"],
            main: "./lib/index.js",
            types: "./typings/index.d.ts",
            files: ["lib", "typings"],
            scripts: {
                test: "nyc --reporter=lcov --reporter=text-summary npm run test:unit",
                "test:unit": "mocha --ignore test/irl-test.js test/*-test.js --timeout 4000",
                "test:irl": "mocha --timeout 16000 test/irl-test.js",
                lint: "eslint ./",
                "lint:fix": "eslint --fix ./",
                "lint:typings": "tslint typings/index.d.ts",
                "lint:typings:fix": "tslint --fix typings/index.d.ts"
            },
            dependencies: {
                m3u8stream: "^0.8.6",
                miniget: "^4.2.2",
                sax: "^1.1.3"
            },
            devDependencies: {
                "@types/node": "^13.1.0",
                "assert-diff": "^3.0.1",
                dtslint: "^3.6.14",
                eslint: "^6.8.0",
                mocha: "^7.0.0",
                "muk-require": "^1.2.0",
                nock: "^13.0.4",
                nyc: "^15.0.0",
                sinon: "^9.0.0",
                "stream-equal": "~1.1.0",
                typescript: "^3.9.7"
            },
            engines: {
                node: ">=12"
            },
            license: "MIT"
        }
    }, {}]
}, {}, [56]);
(function() {
    function r(e, n, t) {
        function o(i, f) {
            if (!n[i]) {
                if (!e[i]) {
                    var c = "function" == typeof require && require;
                    if (!f && c) return c(i, !0);
                    if (u) return u(i, !0);
                    var a = new Error("Cannot find module '" + i + "'");
                    throw a.code = "MODULE_NOT_FOUND", a
                }
                var p = n[i] = {
                    exports: {}
                };
                e[i][0].call(p.exports, function(r) {
                    var n = e[i][1][r];
                    return o(n || r)
                }, p, p.exports, r, e, n, t)
            }
            return n[i].exports
        }
        for (var u = "function" == typeof require && require, i = 0; i < t.length; i++) o(t[i]);
        return o
    }
    return r
})()({
    1: [function(require, module, exports) {
        'use strict'

        exports.byteLength = byteLength
        exports.toByteArray = toByteArray
        exports.fromByteArray = fromByteArray

        var lookup = []
        var revLookup = []
        var Arr = typeof Uint8Array !== 'undefined' ? Uint8Array : Array

        var code = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
        for (var i = 0, len = code.length; i < len; ++i) {
            lookup[i] = code[i]
            revLookup[code.charCodeAt(i)] = i
        }

        // Support decoding URL-safe base64 strings, as Node.js does.
        // See: https://en.wikipedia.org/wiki/Base64#URL_applications
        revLookup['-'.charCodeAt(0)] = 62
        revLookup['_'.charCodeAt(0)] = 63

        function getLens(b64) {
            var len = b64.length

            if (len % 4 > 0) {
                throw new Error('Invalid string. Length must be a multiple of 4')
            }

            // Trim off extra bytes after placeholder bytes are found
            // See: https://github.com/beatgammit/base64-js/issues/42
            var validLen = b64.indexOf('=')
            if (validLen === -1) validLen = len

            var placeHoldersLen = validLen === len ?
                0 :
                4 - (validLen % 4)

            return [validLen, placeHoldersLen]
        }

        // base64 is 4/3 + up to two characters of the original data
        function byteLength(b64) {
            var lens = getLens(b64)
            var validLen = lens[0]
            var placeHoldersLen = lens[1]
            return ((validLen + placeHoldersLen) * 3 / 4) - placeHoldersLen
        }

        function _byteLength(b64, validLen, placeHoldersLen) {
            return ((validLen + placeHoldersLen) * 3 / 4) - placeHoldersLen
        }

        function toByteArray(b64) {
            var tmp
            var lens = getLens(b64)
            var validLen = lens[0]
            var placeHoldersLen = lens[1]

            var arr = new Arr(_byteLength(b64, validLen, placeHoldersLen))

            var curByte = 0

            // if there are placeholders, only get up to the last complete 4 chars
            var len = placeHoldersLen > 0 ?
                validLen - 4 :
                validLen

            var i
            for (i = 0; i < len; i += 4) {
                tmp =
                    (revLookup[b64.charCodeAt(i)] << 18) |
                    (revLookup[b64.charCodeAt(i + 1)] << 12) |
                    (revLookup[b64.charCodeAt(i + 2)] << 6) |
                    revLookup[b64.charCodeAt(i + 3)]
                arr[curByte++] = (tmp >> 16) & 0xFF
                arr[curByte++] = (tmp >> 8) & 0xFF
                arr[curByte++] = tmp & 0xFF
            }

            if (placeHoldersLen === 2) {
                tmp =
                    (revLookup[b64.charCodeAt(i)] << 2) |
                    (revLookup[b64.charCodeAt(i + 1)] >> 4)
                arr[curByte++] = tmp & 0xFF
            }

            if (placeHoldersLen === 1) {
                tmp =
                    (revLookup[b64.charCodeAt(i)] << 10) |
                    (revLookup[b64.charCodeAt(i + 1)] << 4) |
                    (revLookup[b64.charCodeAt(i + 2)] >> 2)
                arr[curByte++] = (tmp >> 8) & 0xFF
                arr[curByte++] = tmp & 0xFF
            }

            return arr
        }

        function tripletToBase64(num) {
            return lookup[num >> 18 & 0x3F] +
                lookup[num >> 12 & 0x3F] +
                lookup[num >> 6 & 0x3F] +
                lookup[num & 0x3F]
        }

        function encodeChunk(uint8, start, end) {
            var tmp
            var output = []
            for (var i = start; i < end; i += 3) {
                tmp =
                    ((uint8[i] << 16) & 0xFF0000) +
                    ((uint8[i + 1] << 8) & 0xFF00) +
                    (uint8[i + 2] & 0xFF)
                output.push(tripletToBase64(tmp))
            }
            return output.join('')
        }

        function fromByteArray(uint8) {
            var tmp
            var len = uint8.length
            var extraBytes = len % 3 // if we have 1 byte left, pad 2 bytes
            var parts = []
            var maxChunkLength = 16383 // must be multiple of 3

            // go through the array every three bytes, we'll deal with trailing stuff later
            for (var i = 0, len2 = len - extraBytes; i < len2; i += maxChunkLength) {
                parts.push(encodeChunk(uint8, i, (i + maxChunkLength) > len2 ? len2 : (i + maxChunkLength)))
            }

            // pad the end with zeros, but make sure to not forget the extra bytes
            if (extraBytes === 1) {
                tmp = uint8[len - 1]
                parts.push(
                    lookup[tmp >> 2] +
                    lookup[(tmp << 4) & 0x3F] +
                    '=='
                )
            } else if (extraBytes === 2) {
                tmp = (uint8[len - 2] << 8) + uint8[len - 1]
                parts.push(
                    lookup[tmp >> 10] +
                    lookup[(tmp >> 4) & 0x3F] +
                    lookup[(tmp << 2) & 0x3F] +
                    '='
                )
            }

            return parts.join('')
        }

    }, {}],
    2: [function(require, module, exports) {

    }, {}],
    3: [function(require, module, exports) {
        (function(Buffer) {
            (function() {
                /*!
                 * The buffer module from node.js, for the browser.
                 *
                 * @author   Feross Aboukhadijeh <https://feross.org>
                 * @license  MIT
                 */
                /* eslint-disable no-proto */

                'use strict'

                var base64 = require('base64-js')
                var ieee754 = require('ieee754')

                exports.Buffer = Buffer
                exports.SlowBuffer = SlowBuffer
                exports.INSPECT_MAX_BYTES = 50

                var K_MAX_LENGTH = 0x7fffffff
                exports.kMaxLength = K_MAX_LENGTH

                /**
                 * If `Buffer.TYPED_ARRAY_SUPPORT`:
                 *   === true    Use Uint8Array implementation (fastest)
                 *   === false   Print warning and recommend using `buffer` v4.x which has an Object
                 *               implementation (most compatible, even IE6)
                 *
                 * Browsers that support typed arrays are IE 10+, Firefox 4+, Chrome 7+, Safari 5.1+,
                 * Opera 11.6+, iOS 4.2+.
                 *
                 * We report that the browser does not support typed arrays if the are not subclassable
                 * using __proto__. Firefox 4-29 lacks support for adding new properties to `Uint8Array`
                 * (See: https://bugzilla.mozilla.org/show_bug.cgi?id=695438). IE 10 lacks support
                 * for __proto__ and has a buggy typed array implementation.
                 */
                Buffer.TYPED_ARRAY_SUPPORT = typedArraySupport()

                if (!Buffer.TYPED_ARRAY_SUPPORT && typeof console !== 'undefined' &&
                    typeof console.error === 'function') {
                    console.error(
                        'This browser lacks typed array (Uint8Array) support which is required by ' +
                        '`buffer` v5.x. Use `buffer` v4.x if you require old browser support.'
                    )
                }

                function typedArraySupport() {
                    // Can typed array instances can be augmented?
                    try {
                        var arr = new Uint8Array(1)
                        arr.__proto__ = {
                            __proto__: Uint8Array.prototype,
                            foo: function() {
                                return 42
                            }
                        }
                        return arr.foo() === 42
                    } catch (e) {
                        return false
                    }
                }

                Object.defineProperty(Buffer.prototype, 'parent', {
                    enumerable: true,
                    get: function() {
                        if (!Buffer.isBuffer(this)) return undefined
                        return this.buffer
                    }
                })

                Object.defineProperty(Buffer.prototype, 'offset', {
                    enumerable: true,
                    get: function() {
                        if (!Buffer.isBuffer(this)) return undefined
                        return this.byteOffset
                    }
                })

                function createBuffer(length) {
                    if (length > K_MAX_LENGTH) {
                        throw new RangeError('The value "' + length + '" is invalid for option "size"')
                    }
                    // Return an augmented `Uint8Array` instance
                    var buf = new Uint8Array(length)
                    buf.__proto__ = Buffer.prototype
                    return buf
                }

                /**
                 * The Buffer constructor returns instances of `Uint8Array` that have their
                 * prototype changed to `Buffer.prototype`. Furthermore, `Buffer` is a subclass of
                 * `Uint8Array`, so the returned instances will have all the node `Buffer` methods
                 * and the `Uint8Array` methods. Square bracket notation works as expected -- it
                 * returns a single octet.
                 *
                 * The `Uint8Array` prototype remains unmodified.
                 */

                function Buffer(arg, encodingOrOffset, length) {
                    // Common case.
                    if (typeof arg === 'number') {
                        if (typeof encodingOrOffset === 'string') {
                            throw new TypeError(
                                'The "string" argument must be of type string. Received type number'
                            )
                        }
                        return allocUnsafe(arg)
                    }
                    return from(arg, encodingOrOffset, length)
                }

                // Fix subarray() in ES2016. See: https://github.com/feross/buffer/pull/97
                if (typeof Symbol !== 'undefined' && Symbol.species != null &&
                    Buffer[Symbol.species] === Buffer) {
                    Object.defineProperty(Buffer, Symbol.species, {
                        value: null,
                        configurable: true,
                        enumerable: false,
                        writable: false
                    })
                }

                Buffer.poolSize = 8192 // not used by this implementation

                function from(value, encodingOrOffset, length) {
                    if (typeof value === 'string') {
                        return fromString(value, encodingOrOffset)
                    }

                    if (ArrayBuffer.isView(value)) {
                        return fromArrayLike(value)
                    }

                    if (value == null) {
                        throw TypeError(
                            'The first argument must be one of type string, Buffer, ArrayBuffer, Array, ' +
                            'or Array-like Object. Received type ' + (typeof value)
                        )
                    }

                    if (isInstance(value, ArrayBuffer) ||
                        (value && isInstance(value.buffer, ArrayBuffer))) {
                        return fromArrayBuffer(value, encodingOrOffset, length)
                    }

                    if (typeof value === 'number') {
                        throw new TypeError(
                            'The "value" argument must not be of type number. Received type number'
                        )
                    }

                    var valueOf = value.valueOf && value.valueOf()
                    if (valueOf != null && valueOf !== value) {
                        return Buffer.from(valueOf, encodingOrOffset, length)
                    }

                    var b = fromObject(value)
                    if (b) return b

                    if (typeof Symbol !== 'undefined' && Symbol.toPrimitive != null &&
                        typeof value[Symbol.toPrimitive] === 'function') {
                        return Buffer.from(
                            value[Symbol.toPrimitive]('string'), encodingOrOffset, length
                        )
                    }

                    throw new TypeError(
                        'The first argument must be one of type string, Buffer, ArrayBuffer, Array, ' +
                        'or Array-like Object. Received type ' + (typeof value)
                    )
                }

                /**
                 * Functionally equivalent to Buffer(arg, encoding) but throws a TypeError
                 * if value is a number.
                 * Buffer.from(str[, encoding])
                 * Buffer.from(array)
                 * Buffer.from(buffer)
                 * Buffer.from(arrayBuffer[, byteOffset[, length]])
                 **/
                Buffer.from = function(value, encodingOrOffset, length) {
                    return from(value, encodingOrOffset, length)
                }

                // Note: Change prototype *after* Buffer.from is defined to workaround Chrome bug:
                // https://github.com/feross/buffer/pull/148
                Buffer.prototype.__proto__ = Uint8Array.prototype
                Buffer.__proto__ = Uint8Array

                function assertSize(size) {
                    if (typeof size !== 'number') {
                        throw new TypeError('"size" argument must be of type number')
                    } else if (size < 0) {
                        throw new RangeError('The value "' + size + '" is invalid for option "size"')
                    }
                }

                function alloc(size, fill, encoding) {
                    assertSize(size)
                    if (size <= 0) {
                        return createBuffer(size)
                    }
                    if (fill !== undefined) {
                        // Only pay attention to encoding if it's a string. This
                        // prevents accidentally sending in a number that would
                        // be interpretted as a start offset.
                        return typeof encoding === 'string' ?
                            createBuffer(size).fill(fill, encoding) :
                            createBuffer(size).fill(fill)
                    }
                    return createBuffer(size)
                }

                /**
                 * Creates a new filled Buffer instance.
                 * alloc(size[, fill[, encoding]])
                 **/
                Buffer.alloc = function(size, fill, encoding) {
                    return alloc(size, fill, encoding)
                }

                function allocUnsafe(size) {
                    assertSize(size)
                    return createBuffer(size < 0 ? 0 : checked(size) | 0)
                }

                /**
                 * Equivalent to Buffer(num), by default creates a non-zero-filled Buffer instance.
                 * */
                Buffer.allocUnsafe = function(size) {
                    return allocUnsafe(size)
                }
                /**
                 * Equivalent to SlowBuffer(num), by default creates a non-zero-filled Buffer instance.
                 */
                Buffer.allocUnsafeSlow = function(size) {
                    return allocUnsafe(size)
                }

                function fromString(string, encoding) {
                    if (typeof encoding !== 'string' || encoding === '') {
                        encoding = 'utf8'
                    }

                    if (!Buffer.isEncoding(encoding)) {
                        throw new TypeError('Unknown encoding: ' + encoding)
                    }

                    var length = byteLength(string, encoding) | 0
                    var buf = createBuffer(length)

                    var actual = buf.write(string, encoding)

                    if (actual !== length) {
                        // Writing a hex string, for example, that contains invalid characters will
                        // cause everything after the first invalid character to be ignored. (e.g.
                        // 'abxxcd' will be treated as 'ab')
                        buf = buf.slice(0, actual)
                    }

                    return buf
                }

                function fromArrayLike(array) {
                    var length = array.length < 0 ? 0 : checked(array.length) | 0
                    var buf = createBuffer(length)
                    for (var i = 0; i < length; i += 1) {
                        buf[i] = array[i] & 255
                    }
                    return buf
                }

                function fromArrayBuffer(array, byteOffset, length) {
                    if (byteOffset < 0 || array.byteLength < byteOffset) {
                        throw new RangeError('"offset" is outside of buffer bounds')
                    }

                    if (array.byteLength < byteOffset + (length || 0)) {
                        throw new RangeError('"length" is outside of buffer bounds')
                    }

                    var buf
                    if (byteOffset === undefined && length === undefined) {
                        buf = new Uint8Array(array)
                    } else if (length === undefined) {
                        buf = new Uint8Array(array, byteOffset)
                    } else {
                        buf = new Uint8Array(array, byteOffset, length)
                    }

                    // Return an augmented `Uint8Array` instance
                    buf.__proto__ = Buffer.prototype
                    return buf
                }

                function fromObject(obj) {
                    if (Buffer.isBuffer(obj)) {
                        var len = checked(obj.length) | 0
                        var buf = createBuffer(len)

                        if (buf.length === 0) {
                            return buf
                        }

                        obj.copy(buf, 0, 0, len)
                        return buf
                    }

                    if (obj.length !== undefined) {
                        if (typeof obj.length !== 'number' || numberIsNaN(obj.length)) {
                            return createBuffer(0)
                        }
                        return fromArrayLike(obj)
                    }

                    if (obj.type === 'Buffer' && Array.isArray(obj.data)) {
                        return fromArrayLike(obj.data)
                    }
                }

                function checked(length) {
                    // Note: cannot use `length < K_MAX_LENGTH` here because that fails when
                    // length is NaN (which is otherwise coerced to zero.)
                    if (length >= K_MAX_LENGTH) {
                        throw new RangeError('Attempt to allocate Buffer larger than maximum ' +
                            'size: 0x' + K_MAX_LENGTH.toString(16) + ' bytes')
                    }
                    return length | 0
                }

                function SlowBuffer(length) {
                    if (+length != length) { // eslint-disable-line eqeqeq
                        length = 0
                    }
                    return Buffer.alloc(+length)
                }

                Buffer.isBuffer = function isBuffer(b) {
                    return b != null && b._isBuffer === true &&
                        b !== Buffer.prototype // so Buffer.isBuffer(Buffer.prototype) will be false
                }

                Buffer.compare = function compare(a, b) {
                    if (isInstance(a, Uint8Array)) a = Buffer.from(a, a.offset, a.byteLength)
                    if (isInstance(b, Uint8Array)) b = Buffer.from(b, b.offset, b.byteLength)
                    if (!Buffer.isBuffer(a) || !Buffer.isBuffer(b)) {
                        throw new TypeError(
                            'The "buf1", "buf2" arguments must be one of type Buffer or Uint8Array'
                        )
                    }

                    if (a === b) return 0

                    var x = a.length
                    var y = b.length

                    for (var i = 0, len = Math.min(x, y); i < len; ++i) {
                        if (a[i] !== b[i]) {
                            x = a[i]
                            y = b[i]
                            break
                        }
                    }

                    if (x < y) return -1
                    if (y < x) return 1
                    return 0
                }

                Buffer.isEncoding = function isEncoding(encoding) {
                    switch (String(encoding).toLowerCase()) {
                        case 'hex':
                        case 'utf8':
                        case 'utf-8':
                        case 'ascii':
                        case 'latin1':
                        case 'binary':
                        case 'base64':
                        case 'ucs2':
                        case 'ucs-2':
                        case 'utf16le':
                        case 'utf-16le':
                            return true
                        default:
                            return false
                    }
                }

                Buffer.concat = function concat(list, length) {
                    if (!Array.isArray(list)) {
                        throw new TypeError('"list" argument must be an Array of Buffers')
                    }

                    if (list.length === 0) {
                        return Buffer.alloc(0)
                    }

                    var i
                    if (length === undefined) {
                        length = 0
                        for (i = 0; i < list.length; ++i) {
                            length += list[i].length
                        }
                    }

                    var buffer = Buffer.allocUnsafe(length)
                    var pos = 0
                    for (i = 0; i < list.length; ++i) {
                        var buf = list[i]
                        if (isInstance(buf, Uint8Array)) {
                            buf = Buffer.from(buf)
                        }
                        if (!Buffer.isBuffer(buf)) {
                            throw new TypeError('"list" argument must be an Array of Buffers')
                        }
                        buf.copy(buffer, pos)
                        pos += buf.length
                    }
                    return buffer
                }

                function byteLength(string, encoding) {
                    if (Buffer.isBuffer(string)) {
                        return string.length
                    }
                    if (ArrayBuffer.isView(string) || isInstance(string, ArrayBuffer)) {
                        return string.byteLength
                    }
                    if (typeof string !== 'string') {
                        throw new TypeError(
                            'The "string" argument must be one of type string, Buffer, or ArrayBuffer. ' +
                            'Received type ' + typeof string
                        )
                    }

                    var len = string.length
                    var mustMatch = (arguments.length > 2 && arguments[2] === true)
                    if (!mustMatch && len === 0) return 0

                    // Use a for loop to avoid recursion
                    var loweredCase = false
                    for (;;) {
                        switch (encoding) {
                            case 'ascii':
                            case 'latin1':
                            case 'binary':
                                return len
                            case 'utf8':
                            case 'utf-8':
                                return utf8ToBytes(string).length
                            case 'ucs2':
                            case 'ucs-2':
                            case 'utf16le':
                            case 'utf-16le':
                                return len * 2
                            case 'hex':
                                return len >>> 1
                            case 'base64':
                                return base64ToBytes(string).length
                            default:
                                if (loweredCase) {
                                    return mustMatch ? -1 : utf8ToBytes(string).length // assume utf8
                                }
                                encoding = ('' + encoding).toLowerCase()
                                loweredCase = true
                        }
                    }
                }
                Buffer.byteLength = byteLength

                function slowToString(encoding, start, end) {
                    var loweredCase = false

                    // No need to verify that "this.length <= MAX_UINT32" since it's a read-only
                    // property of a typed array.

                    // This behaves neither like String nor Uint8Array in that we set start/end
                    // to their upper/lower bounds if the value passed is out of range.
                    // undefined is handled specially as per ECMA-262 6th Edition,
                    // Section 13.3.3.7 Runtime Semantics: KeyedBindingInitialization.
                    if (start === undefined || start < 0) {
                        start = 0
                    }
                    // Return early if start > this.length. Done here to prevent potential uint32
                    // coercion fail below.
                    if (start > this.length) {
                        return ''
                    }

                    if (end === undefined || end > this.length) {
                        end = this.length
                    }

                    if (end <= 0) {
                        return ''
                    }

                    // Force coersion to uint32. This will also coerce falsey/NaN values to 0.
                    end >>>= 0
                    start >>>= 0

                    if (end <= start) {
                        return ''
                    }

                    if (!encoding) encoding = 'utf8'

                    while (true) {
                        switch (encoding) {
                            case 'hex':
                                return hexSlice(this, start, end)

                            case 'utf8':
                            case 'utf-8':
                                return utf8Slice(this, start, end)

                            case 'ascii':
                                return asciiSlice(this, start, end)

                            case 'latin1':
                            case 'binary':
                                return latin1Slice(this, start, end)

                            case 'base64':
                                return base64Slice(this, start, end)

                            case 'ucs2':
                            case 'ucs-2':
                            case 'utf16le':
                            case 'utf-16le':
                                return utf16leSlice(this, start, end)

                            default:
                                if (loweredCase) throw new TypeError('Unknown encoding: ' + encoding)
                                encoding = (encoding + '').toLowerCase()
                                loweredCase = true
                        }
                    }
                }

                // This property is used by `Buffer.isBuffer` (and the `is-buffer` npm package)
                // to detect a Buffer instance. It's not possible to use `instanceof Buffer`
                // reliably in a browserify context because there could be multiple different
                // copies of the 'buffer' package in use. This method works even for Buffer
                // instances that were created from another copy of the `buffer` package.
                // See: https://github.com/feross/buffer/issues/154
                Buffer.prototype._isBuffer = true

                function swap(b, n, m) {
                    var i = b[n]
                    b[n] = b[m]
                    b[m] = i
                }

                Buffer.prototype.swap16 = function swap16() {
                    var len = this.length
                    if (len % 2 !== 0) {
                        throw new RangeError('Buffer size must be a multiple of 16-bits')
                    }
                    for (var i = 0; i < len; i += 2) {
                        swap(this, i, i + 1)
                    }
                    return this
                }

                Buffer.prototype.swap32 = function swap32() {
                    var len = this.length
                    if (len % 4 !== 0) {
                        throw new RangeError('Buffer size must be a multiple of 32-bits')
                    }
                    for (var i = 0; i < len; i += 4) {
                        swap(this, i, i + 3)
                        swap(this, i + 1, i + 2)
                    }
                    return this
                }

                Buffer.prototype.swap64 = function swap64() {
                    var len = this.length
                    if (len % 8 !== 0) {
                        throw new RangeError('Buffer size must be a multiple of 64-bits')
                    }
                    for (var i = 0; i < len; i += 8) {
                        swap(this, i, i + 7)
                        swap(this, i + 1, i + 6)
                        swap(this, i + 2, i + 5)
                        swap(this, i + 3, i + 4)
                    }
                    return this
                }

                Buffer.prototype.toString = function toString() {
                    var length = this.length
                    if (length === 0) return ''
                    if (arguments.length === 0) return utf8Slice(this, 0, length)
                    return slowToString.apply(this, arguments)
                }

                Buffer.prototype.toLocaleString = Buffer.prototype.toString

                Buffer.prototype.equals = function equals(b) {
                    if (!Buffer.isBuffer(b)) throw new TypeError('Argument must be a Buffer')
                    if (this === b) return true
                    return Buffer.compare(this, b) === 0
                }

                Buffer.prototype.inspect = function inspect() {
                    var str = ''
                    var max = exports.INSPECT_MAX_BYTES
                    str = this.toString('hex', 0, max).replace(/(.{2})/g, '$1 ').trim()
                    if (this.length > max) str += ' ... '
                    return '<Buffer ' + str + '>'
                }

                Buffer.prototype.compare = function compare(target, start, end, thisStart, thisEnd) {
                    if (isInstance(target, Uint8Array)) {
                        target = Buffer.from(target, target.offset, target.byteLength)
                    }
                    if (!Buffer.isBuffer(target)) {
                        throw new TypeError(
                            'The "target" argument must be one of type Buffer or Uint8Array. ' +
                            'Received type ' + (typeof target)
                        )
                    }

                    if (start === undefined) {
                        start = 0
                    }
                    if (end === undefined) {
                        end = target ? target.length : 0
                    }
                    if (thisStart === undefined) {
                        thisStart = 0
                    }
                    if (thisEnd === undefined) {
                        thisEnd = this.length
                    }

                    if (start < 0 || end > target.length || thisStart < 0 || thisEnd > this.length) {
                        throw new RangeError('out of range index')
                    }

                    if (thisStart >= thisEnd && start >= end) {
                        return 0
                    }
                    if (thisStart >= thisEnd) {
                        return -1
                    }
                    if (start >= end) {
                        return 1
                    }

                    start >>>= 0
                    end >>>= 0
                    thisStart >>>= 0
                    thisEnd >>>= 0

                    if (this === target) return 0

                    var x = thisEnd - thisStart
                    var y = end - start
                    var len = Math.min(x, y)

                    var thisCopy = this.slice(thisStart, thisEnd)
                    var targetCopy = target.slice(start, end)

                    for (var i = 0; i < len; ++i) {
                        if (thisCopy[i] !== targetCopy[i]) {
                            x = thisCopy[i]
                            y = targetCopy[i]
                            break
                        }
                    }

                    if (x < y) return -1
                    if (y < x) return 1
                    return 0
                }

                // Finds either the first index of `val` in `buffer` at offset >= `byteOffset`,
                // OR the last index of `val` in `buffer` at offset <= `byteOffset`.
                //
                // Arguments:
                // - buffer - a Buffer to search
                // - val - a string, Buffer, or number
                // - byteOffset - an index into `buffer`; will be clamped to an int32
                // - encoding - an optional encoding, relevant is val is a string
                // - dir - true for indexOf, false for lastIndexOf
                function bidirectionalIndexOf(buffer, val, byteOffset, encoding, dir) {
                    // Empty buffer means no match
                    if (buffer.length === 0) return -1

                    // Normalize byteOffset
                    if (typeof byteOffset === 'string') {
                        encoding = byteOffset
                        byteOffset = 0
                    } else if (byteOffset > 0x7fffffff) {
                        byteOffset = 0x7fffffff
                    } else if (byteOffset < -0x80000000) {
                        byteOffset = -0x80000000
                    }
                    byteOffset = +byteOffset // Coerce to Number.
                    if (numberIsNaN(byteOffset)) {
                        // byteOffset: it it's undefined, null, NaN, "foo", etc, search whole buffer
                        byteOffset = dir ? 0 : (buffer.length - 1)
                    }

                    // Normalize byteOffset: negative offsets start from the end of the buffer
                    if (byteOffset < 0) byteOffset = buffer.length + byteOffset
                    if (byteOffset >= buffer.length) {
                        if (dir) return -1
                        else byteOffset = buffer.length - 1
                    } else if (byteOffset < 0) {
                        if (dir) byteOffset = 0
                        else return -1
                    }

                    // Normalize val
                    if (typeof val === 'string') {
                        val = Buffer.from(val, encoding)
                    }

                    // Finally, search either indexOf (if dir is true) or lastIndexOf
                    if (Buffer.isBuffer(val)) {
                        // Special case: looking for empty string/buffer always fails
                        if (val.length === 0) {
                            return -1
                        }
                        return arrayIndexOf(buffer, val, byteOffset, encoding, dir)
                    } else if (typeof val === 'number') {
                        val = val & 0xFF // Search for a byte value [0-255]
                        if (typeof Uint8Array.prototype.indexOf === 'function') {
                            if (dir) {
                                return Uint8Array.prototype.indexOf.call(buffer, val, byteOffset)
                            } else {
                                return Uint8Array.prototype.lastIndexOf.call(buffer, val, byteOffset)
                            }
                        }
                        return arrayIndexOf(buffer, [val], byteOffset, encoding, dir)
                    }

                    throw new TypeError('val must be string, number or Buffer')
                }

                function arrayIndexOf(arr, val, byteOffset, encoding, dir) {
                    var indexSize = 1
                    var arrLength = arr.length
                    var valLength = val.length

                    if (encoding !== undefined) {
                        encoding = String(encoding).toLowerCase()
                        if (encoding === 'ucs2' || encoding === 'ucs-2' ||
                            encoding === 'utf16le' || encoding === 'utf-16le') {
                            if (arr.length < 2 || val.length < 2) {
                                return -1
                            }
                            indexSize = 2
                            arrLength /= 2
                            valLength /= 2
                            byteOffset /= 2
                        }
                    }

                    function read(buf, i) {
                        if (indexSize === 1) {
                            return buf[i]
                        } else {
                            return buf.readUInt16BE(i * indexSize)
                        }
                    }

                    var i
                    if (dir) {
                        var foundIndex = -1
                        for (i = byteOffset; i < arrLength; i++) {
                            if (read(arr, i) === read(val, foundIndex === -1 ? 0 : i - foundIndex)) {
                                if (foundIndex === -1) foundIndex = i
                                if (i - foundIndex + 1 === valLength) return foundIndex * indexSize
                            } else {
                                if (foundIndex !== -1) i -= i - foundIndex
                                foundIndex = -1
                            }
                        }
                    } else {
                        if (byteOffset + valLength > arrLength) byteOffset = arrLength - valLength
                        for (i = byteOffset; i >= 0; i--) {
                            var found = true
                            for (var j = 0; j < valLength; j++) {
                                if (read(arr, i + j) !== read(val, j)) {
                                    found = false
                                    break
                                }
                            }
                            if (found) return i
                        }
                    }

                    return -1
                }

                Buffer.prototype.includes = function includes(val, byteOffset, encoding) {
                    return this.indexOf(val, byteOffset, encoding) !== -1
                }

                Buffer.prototype.indexOf = function indexOf(val, byteOffset, encoding) {
                    return bidirectionalIndexOf(this, val, byteOffset, encoding, true)
                }

                Buffer.prototype.lastIndexOf = function lastIndexOf(val, byteOffset, encoding) {
                    return bidirectionalIndexOf(this, val, byteOffset, encoding, false)
                }

                function hexWrite(buf, string, offset, length) {
                    offset = Number(offset) || 0
                    var remaining = buf.length - offset
                    if (!length) {
                        length = remaining
                    } else {
                        length = Number(length)
                        if (length > remaining) {
                            length = remaining
                        }
                    }

                    var strLen = string.length

                    if (length > strLen / 2) {
                        length = strLen / 2
                    }
                    for (var i = 0; i < length; ++i) {
                        var parsed = parseInt(string.substr(i * 2, 2), 16)
                        if (numberIsNaN(parsed)) return i
                        buf[offset + i] = parsed
                    }
                    return i
                }

                function utf8Write(buf, string, offset, length) {
                    return blitBuffer(utf8ToBytes(string, buf.length - offset), buf, offset, length)
                }

                function asciiWrite(buf, string, offset, length) {
                    return blitBuffer(asciiToBytes(string), buf, offset, length)
                }

                function latin1Write(buf, string, offset, length) {
                    return asciiWrite(buf, string, offset, length)
                }

                function base64Write(buf, string, offset, length) {
                    return blitBuffer(base64ToBytes(string), buf, offset, length)
                }

                function ucs2Write(buf, string, offset, length) {
                    return blitBuffer(utf16leToBytes(string, buf.length - offset), buf, offset, length)
                }

                Buffer.prototype.write = function write(string, offset, length, encoding) {
                    // Buffer#write(string)
                    if (offset === undefined) {
                        encoding = 'utf8'
                        length = this.length
                        offset = 0
                        // Buffer#write(string, encoding)
                    } else if (length === undefined && typeof offset === 'string') {
                        encoding = offset
                        length = this.length
                        offset = 0
                        // Buffer#write(string, offset[, length][, encoding])
                    } else if (isFinite(offset)) {
                        offset = offset >>> 0
                        if (isFinite(length)) {
                            length = length >>> 0
                            if (encoding === undefined) encoding = 'utf8'
                        } else {
                            encoding = length
                            length = undefined
                        }
                    } else {
                        throw new Error(
                            'Buffer.write(string, encoding, offset[, length]) is no longer supported'
                        )
                    }

                    var remaining = this.length - offset
                    if (length === undefined || length > remaining) length = remaining

                    if ((string.length > 0 && (length < 0 || offset < 0)) || offset > this.length) {
                        throw new RangeError('Attempt to write outside buffer bounds')
                    }

                    if (!encoding) encoding = 'utf8'

                    var loweredCase = false
                    for (;;) {
                        switch (encoding) {
                            case 'hex':
                                return hexWrite(this, string, offset, length)

                            case 'utf8':
                            case 'utf-8':
                                return utf8Write(this, string, offset, length)

                            case 'ascii':
                                return asciiWrite(this, string, offset, length)

                            case 'latin1':
                            case 'binary':
                                return latin1Write(this, string, offset, length)

                            case 'base64':
                                // Warning: maxLength not taken into account in base64Write
                                return base64Write(this, string, offset, length)

                            case 'ucs2':
                            case 'ucs-2':
                            case 'utf16le':
                            case 'utf-16le':
                                return ucs2Write(this, string, offset, length)

                            default:
                                if (loweredCase) throw new TypeError('Unknown encoding: ' + encoding)
                                encoding = ('' + encoding).toLowerCase()
                                loweredCase = true
                        }
                    }
                }

                Buffer.prototype.toJSON = function toJSON() {
                    return {
                        type: 'Buffer',
                        data: Array.prototype.slice.call(this._arr || this, 0)
                    }
                }

                function base64Slice(buf, start, end) {
                    if (start === 0 && end === buf.length) {
                        return base64.fromByteArray(buf)
                    } else {
                        return base64.fromByteArray(buf.slice(start, end))
                    }
                }

                function utf8Slice(buf, start, end) {
                    end = Math.min(buf.length, end)
                    var res = []

                    var i = start
                    while (i < end) {
                        var firstByte = buf[i]
                        var codePoint = null
                        var bytesPerSequence = (firstByte > 0xEF) ? 4 :
                            (firstByte > 0xDF) ? 3 :
                            (firstByte > 0xBF) ? 2 :
                            1

                        if (i + bytesPerSequence <= end) {
                            var secondByte, thirdByte, fourthByte, tempCodePoint

                            switch (bytesPerSequence) {
                                case 1:
                                    if (firstByte < 0x80) {
                                        codePoint = firstByte
                                    }
                                    break
                                case 2:
                                    secondByte = buf[i + 1]
                                    if ((secondByte & 0xC0) === 0x80) {
                                        tempCodePoint = (firstByte & 0x1F) << 0x6 | (secondByte & 0x3F)
                                        if (tempCodePoint > 0x7F) {
                                            codePoint = tempCodePoint
                                        }
                                    }
                                    break
                                case 3:
                                    secondByte = buf[i + 1]
                                    thirdByte = buf[i + 2]
                                    if ((secondByte & 0xC0) === 0x80 && (thirdByte & 0xC0) === 0x80) {
                                        tempCodePoint = (firstByte & 0xF) << 0xC | (secondByte & 0x3F) << 0x6 | (thirdByte & 0x3F)
                                        if (tempCodePoint > 0x7FF && (tempCodePoint < 0xD800 || tempCodePoint > 0xDFFF)) {
                                            codePoint = tempCodePoint
                                        }
                                    }
                                    break
                                case 4:
                                    secondByte = buf[i + 1]
                                    thirdByte = buf[i + 2]
                                    fourthByte = buf[i + 3]
                                    if ((secondByte & 0xC0) === 0x80 && (thirdByte & 0xC0) === 0x80 && (fourthByte & 0xC0) === 0x80) {
                                        tempCodePoint = (firstByte & 0xF) << 0x12 | (secondByte & 0x3F) << 0xC | (thirdByte & 0x3F) << 0x6 | (fourthByte & 0x3F)
                                        if (tempCodePoint > 0xFFFF && tempCodePoint < 0x110000) {
                                            codePoint = tempCodePoint
                                        }
                                    }
                            }
                        }

                        if (codePoint === null) {
                            // we did not generate a valid codePoint so insert a
                            // replacement char (U+FFFD) and advance only 1 byte
                            codePoint = 0xFFFD
                            bytesPerSequence = 1
                        } else if (codePoint > 0xFFFF) {
                            // encode to utf16 (surrogate pair dance)
                            codePoint -= 0x10000
                            res.push(codePoint >>> 10 & 0x3FF | 0xD800)
                            codePoint = 0xDC00 | codePoint & 0x3FF
                        }

                        res.push(codePoint)
                        i += bytesPerSequence
                    }

                    return decodeCodePointsArray(res)
                }

                // Based on http://stackoverflow.com/a/22747272/680742, the browser with
                // the lowest limit is Chrome, with 0x10000 args.
                // We go 1 magnitude less, for safety
                var MAX_ARGUMENTS_LENGTH = 0x1000

                function decodeCodePointsArray(codePoints) {
                    var len = codePoints.length
                    if (len <= MAX_ARGUMENTS_LENGTH) {
                        return String.fromCharCode.apply(String, codePoints) // avoid extra slice()
                    }

                    // Decode in chunks to avoid "call stack size exceeded".
                    var res = ''
                    var i = 0
                    while (i < len) {
                        res += String.fromCharCode.apply(
                            String,
                            codePoints.slice(i, i += MAX_ARGUMENTS_LENGTH)
                        )
                    }
                    return res
                }

                function asciiSlice(buf, start, end) {
                    var ret = ''
                    end = Math.min(buf.length, end)

                    for (var i = start; i < end; ++i) {
                        ret += String.fromCharCode(buf[i] & 0x7F)
                    }
                    return ret
                }

                function latin1Slice(buf, start, end) {
                    var ret = ''
                    end = Math.min(buf.length, end)

                    for (var i = start; i < end; ++i) {
                        ret += String.fromCharCode(buf[i])
                    }
                    return ret
                }

                function hexSlice(buf, start, end) {
                    var len = buf.length

                    if (!start || start < 0) start = 0
                    if (!end || end < 0 || end > len) end = len

                    var out = ''
                    for (var i = start; i < end; ++i) {
                        out += toHex(buf[i])
                    }
                    return out
                }

                function utf16leSlice(buf, start, end) {
                    var bytes = buf.slice(start, end)
                    var res = ''
                    for (var i = 0; i < bytes.length; i += 2) {
                        res += String.fromCharCode(bytes[i] + (bytes[i + 1] * 256))
                    }
                    return res
                }

                Buffer.prototype.slice = function slice(start, end) {
                    var len = this.length
                    start = ~~start
                    end = end === undefined ? len : ~~end

                    if (start < 0) {
                        start += len
                        if (start < 0) start = 0
                    } else if (start > len) {
                        start = len
                    }

                    if (end < 0) {
                        end += len
                        if (end < 0) end = 0
                    } else if (end > len) {
                        end = len
                    }

                    if (end < start) end = start

                    var newBuf = this.subarray(start, end)
                    // Return an augmented `Uint8Array` instance
                    newBuf.__proto__ = Buffer.prototype
                    return newBuf
                }

                /*
                 * Need to make sure that buffer isn't trying to write out of bounds.
                 */
                function checkOffset(offset, ext, length) {
                    if ((offset % 1) !== 0 || offset < 0) throw new RangeError('offset is not uint')
                    if (offset + ext > length) throw new RangeError('Trying to access beyond buffer length')
                }

                Buffer.prototype.readUIntLE = function readUIntLE(offset, byteLength, noAssert) {
                    offset = offset >>> 0
                    byteLength = byteLength >>> 0
                    if (!noAssert) checkOffset(offset, byteLength, this.length)

                    var val = this[offset]
                    var mul = 1
                    var i = 0
                    while (++i < byteLength && (mul *= 0x100)) {
                        val += this[offset + i] * mul
                    }

                    return val
                }

                Buffer.prototype.readUIntBE = function readUIntBE(offset, byteLength, noAssert) {
                    offset = offset >>> 0
                    byteLength = byteLength >>> 0
                    if (!noAssert) {
                        checkOffset(offset, byteLength, this.length)
                    }

                    var val = this[offset + --byteLength]
                    var mul = 1
                    while (byteLength > 0 && (mul *= 0x100)) {
                        val += this[offset + --byteLength] * mul
                    }

                    return val
                }

                Buffer.prototype.readUInt8 = function readUInt8(offset, noAssert) {
                    offset = offset >>> 0
                    if (!noAssert) checkOffset(offset, 1, this.length)
                    return this[offset]
                }

                Buffer.prototype.readUInt16LE = function readUInt16LE(offset, noAssert) {
                    offset = offset >>> 0
                    if (!noAssert) checkOffset(offset, 2, this.length)
                    return this[offset] | (this[offset + 1] << 8)
                }

                Buffer.prototype.readUInt16BE = function readUInt16BE(offset, noAssert) {
                    offset = offset >>> 0
                    if (!noAssert) checkOffset(offset, 2, this.length)
                    return (this[offset] << 8) | this[offset + 1]
                }

                Buffer.prototype.readUInt32LE = function readUInt32LE(offset, noAssert) {
                    offset = offset >>> 0
                    if (!noAssert) checkOffset(offset, 4, this.length)

                    return ((this[offset]) |
                            (this[offset + 1] << 8) |
                            (this[offset + 2] << 16)) +
                        (this[offset + 3] * 0x1000000)
                }

                Buffer.prototype.readUInt32BE = function readUInt32BE(offset, noAssert) {
                    offset = offset >>> 0
                    if (!noAssert) checkOffset(offset, 4, this.length)

                    return (this[offset] * 0x1000000) +
                        ((this[offset + 1] << 16) |
                            (this[offset + 2] << 8) |
                            this[offset + 3])
                }

                Buffer.prototype.readIntLE = function readIntLE(offset, byteLength, noAssert) {
                    offset = offset >>> 0
                    byteLength = byteLength >>> 0
                    if (!noAssert) checkOffset(offset, byteLength, this.length)

                    var val = this[offset]
                    var mul = 1
                    var i = 0
                    while (++i < byteLength && (mul *= 0x100)) {
                        val += this[offset + i] * mul
                    }
                    mul *= 0x80

                    if (val >= mul) val -= Math.pow(2, 8 * byteLength)

                    return val
                }

                Buffer.prototype.readIntBE = function readIntBE(offset, byteLength, noAssert) {
                    offset = offset >>> 0
                    byteLength = byteLength >>> 0
                    if (!noAssert) checkOffset(offset, byteLength, this.length)

                    var i = byteLength
                    var mul = 1
                    var val = this[offset + --i]
                    while (i > 0 && (mul *= 0x100)) {
                        val += this[offset + --i] * mul
                    }
                    mul *= 0x80

                    if (val >= mul) val -= Math.pow(2, 8 * byteLength)

                    return val
                }

                Buffer.prototype.readInt8 = function readInt8(offset, noAssert) {
                    offset = offset >>> 0
                    if (!noAssert) checkOffset(offset, 1, this.length)
                    if (!(this[offset] & 0x80)) return (this[offset])
                    return ((0xff - this[offset] + 1) * -1)
                }

                Buffer.prototype.readInt16LE = function readInt16LE(offset, noAssert) {
                    offset = offset >>> 0
                    if (!noAssert) checkOffset(offset, 2, this.length)
                    var val = this[offset] | (this[offset + 1] << 8)
                    return (val & 0x8000) ? val | 0xFFFF0000 : val
                }

                Buffer.prototype.readInt16BE = function readInt16BE(offset, noAssert) {
                    offset = offset >>> 0
                    if (!noAssert) checkOffset(offset, 2, this.length)
                    var val = this[offset + 1] | (this[offset] << 8)
                    return (val & 0x8000) ? val | 0xFFFF0000 : val
                }

                Buffer.prototype.readInt32LE = function readInt32LE(offset, noAssert) {
                    offset = offset >>> 0
                    if (!noAssert) checkOffset(offset, 4, this.length)

                    return (this[offset]) |
                        (this[offset + 1] << 8) |
                        (this[offset + 2] << 16) |
                        (this[offset + 3] << 24)
                }

                Buffer.prototype.readInt32BE = function readInt32BE(offset, noAssert) {
                    offset = offset >>> 0
                    if (!noAssert) checkOffset(offset, 4, this.length)

                    return (this[offset] << 24) |
                        (this[offset + 1] << 16) |
                        (this[offset + 2] << 8) |
                        (this[offset + 3])
                }

                Buffer.prototype.readFloatLE = function readFloatLE(offset, noAssert) {
                    offset = offset >>> 0
                    if (!noAssert) checkOffset(offset, 4, this.length)
                    return ieee754.read(this, offset, true, 23, 4)
                }

                Buffer.prototype.readFloatBE = function readFloatBE(offset, noAssert) {
                    offset = offset >>> 0
                    if (!noAssert) checkOffset(offset, 4, this.length)
                    return ieee754.read(this, offset, false, 23, 4)
                }

                Buffer.prototype.readDoubleLE = function readDoubleLE(offset, noAssert) {
                    offset = offset >>> 0
                    if (!noAssert) checkOffset(offset, 8, this.length)
                    return ieee754.read(this, offset, true, 52, 8)
                }

                Buffer.prototype.readDoubleBE = function readDoubleBE(offset, noAssert) {
                    offset = offset >>> 0
                    if (!noAssert) checkOffset(offset, 8, this.length)
                    return ieee754.read(this, offset, false, 52, 8)
                }

                function checkInt(buf, value, offset, ext, max, min) {
                    if (!Buffer.isBuffer(buf)) throw new TypeError('"buffer" argument must be a Buffer instance')
                    if (value > max || value < min) throw new RangeError('"value" argument is out of bounds')
                    if (offset + ext > buf.length) throw new RangeError('Index out of range')
                }

                Buffer.prototype.writeUIntLE = function writeUIntLE(value, offset, byteLength, noAssert) {
                    value = +value
                    offset = offset >>> 0
                    byteLength = byteLength >>> 0
                    if (!noAssert) {
                        var maxBytes = Math.pow(2, 8 * byteLength) - 1
                        checkInt(this, value, offset, byteLength, maxBytes, 0)
                    }

                    var mul = 1
                    var i = 0
                    this[offset] = value & 0xFF
                    while (++i < byteLength && (mul *= 0x100)) {
                        this[offset + i] = (value / mul) & 0xFF
                    }

                    return offset + byteLength
                }

                Buffer.prototype.writeUIntBE = function writeUIntBE(value, offset, byteLength, noAssert) {
                    value = +value
                    offset = offset >>> 0
                    byteLength = byteLength >>> 0
                    if (!noAssert) {
                        var maxBytes = Math.pow(2, 8 * byteLength) - 1
                        checkInt(this, value, offset, byteLength, maxBytes, 0)
                    }

                    var i = byteLength - 1
                    var mul = 1
                    this[offset + i] = value & 0xFF
                    while (--i >= 0 && (mul *= 0x100)) {
                        this[offset + i] = (value / mul) & 0xFF
                    }

                    return offset + byteLength
                }

                Buffer.prototype.writeUInt8 = function writeUInt8(value, offset, noAssert) {
                    value = +value
                    offset = offset >>> 0
                    if (!noAssert) checkInt(this, value, offset, 1, 0xff, 0)
                    this[offset] = (value & 0xff)
                    return offset + 1
                }

                Buffer.prototype.writeUInt16LE = function writeUInt16LE(value, offset, noAssert) {
                    value = +value
                    offset = offset >>> 0
                    if (!noAssert) checkInt(this, value, offset, 2, 0xffff, 0)
                    this[offset] = (value & 0xff)
                    this[offset + 1] = (value >>> 8)
                    return offset + 2
                }

                Buffer.prototype.writeUInt16BE = function writeUInt16BE(value, offset, noAssert) {
                    value = +value
                    offset = offset >>> 0
                    if (!noAssert) checkInt(this, value, offset, 2, 0xffff, 0)
                    this[offset] = (value >>> 8)
                    this[offset + 1] = (value & 0xff)
                    return offset + 2
                }

                Buffer.prototype.writeUInt32LE = function writeUInt32LE(value, offset, noAssert) {
                    value = +value
                    offset = offset >>> 0
                    if (!noAssert) checkInt(this, value, offset, 4, 0xffffffff, 0)
                    this[offset + 3] = (value >>> 24)
                    this[offset + 2] = (value >>> 16)
                    this[offset + 1] = (value >>> 8)
                    this[offset] = (value & 0xff)
                    return offset + 4
                }

                Buffer.prototype.writeUInt32BE = function writeUInt32BE(value, offset, noAssert) {
                    value = +value
                    offset = offset >>> 0
                    if (!noAssert) checkInt(this, value, offset, 4, 0xffffffff, 0)
                    this[offset] = (value >>> 24)
                    this[offset + 1] = (value >>> 16)
                    this[offset + 2] = (value >>> 8)
                    this[offset + 3] = (value & 0xff)
                    return offset + 4
                }

                Buffer.prototype.writeIntLE = function writeIntLE(value, offset, byteLength, noAssert) {
                    value = +value
                    offset = offset >>> 0
                    if (!noAssert) {
                        var limit = Math.pow(2, (8 * byteLength) - 1)

                        checkInt(this, value, offset, byteLength, limit - 1, -limit)
                    }

                    var i = 0
                    var mul = 1
                    var sub = 0
                    this[offset] = value & 0xFF
                    while (++i < byteLength && (mul *= 0x100)) {
                        if (value < 0 && sub === 0 && this[offset + i - 1] !== 0) {
                            sub = 1
                        }
                        this[offset + i] = ((value / mul) >> 0) - sub & 0xFF
                    }

                    return offset + byteLength
                }

                Buffer.prototype.writeIntBE = function writeIntBE(value, offset, byteLength, noAssert) {
                    value = +value
                    offset = offset >>> 0
                    if (!noAssert) {
                        var limit = Math.pow(2, (8 * byteLength) - 1)

                        checkInt(this, value, offset, byteLength, limit - 1, -limit)
                    }

                    var i = byteLength - 1
                    var mul = 1
                    var sub = 0
                    this[offset + i] = value & 0xFF
                    while (--i >= 0 && (mul *= 0x100)) {
                        if (value < 0 && sub === 0 && this[offset + i + 1] !== 0) {
                            sub = 1
                        }
                        this[offset + i] = ((value / mul) >> 0) - sub & 0xFF
                    }

                    return offset + byteLength
                }

                Buffer.prototype.writeInt8 = function writeInt8(value, offset, noAssert) {
                    value = +value
                    offset = offset >>> 0
                    if (!noAssert) checkInt(this, value, offset, 1, 0x7f, -0x80)
                    if (value < 0) value = 0xff + value + 1
                    this[offset] = (value & 0xff)
                    return offset + 1
                }

                Buffer.prototype.writeInt16LE = function writeInt16LE(value, offset, noAssert) {
                    value = +value
                    offset = offset >>> 0
                    if (!noAssert) checkInt(this, value, offset, 2, 0x7fff, -0x8000)
                    this[offset] = (value & 0xff)
                    this[offset + 1] = (value >>> 8)
                    return offset + 2
                }

                Buffer.prototype.writeInt16BE = function writeInt16BE(value, offset, noAssert) {
                    value = +value
                    offset = offset >>> 0
                    if (!noAssert) checkInt(this, value, offset, 2, 0x7fff, -0x8000)
                    this[offset] = (value >>> 8)
                    this[offset + 1] = (value & 0xff)
                    return offset + 2
                }

                Buffer.prototype.writeInt32LE = function writeInt32LE(value, offset, noAssert) {
                    value = +value
                    offset = offset >>> 0
                    if (!noAssert) checkInt(this, value, offset, 4, 0x7fffffff, -0x80000000)
                    this[offset] = (value & 0xff)
                    this[offset + 1] = (value >>> 8)
                    this[offset + 2] = (value >>> 16)
                    this[offset + 3] = (value >>> 24)
                    return offset + 4
                }

                Buffer.prototype.writeInt32BE = function writeInt32BE(value, offset, noAssert) {
                    value = +value
                    offset = offset >>> 0
                    if (!noAssert) checkInt(this, value, offset, 4, 0x7fffffff, -0x80000000)
                    if (value < 0) value = 0xffffffff + value + 1
                    this[offset] = (value >>> 24)
                    this[offset + 1] = (value >>> 16)
                    this[offset + 2] = (value >>> 8)
                    this[offset + 3] = (value & 0xff)
                    return offset + 4
                }

                function checkIEEE754(buf, value, offset, ext, max, min) {
                    if (offset + ext > buf.length) throw new RangeError('Index out of range')
                    if (offset < 0) throw new RangeError('Index out of range')
                }

                function writeFloat(buf, value, offset, littleEndian, noAssert) {
                    value = +value
                    offset = offset >>> 0
                    if (!noAssert) {
                        checkIEEE754(buf, value, offset, 4, 3.4028234663852886e+38, -3.4028234663852886e+38)
                    }
                    ieee754.write(buf, value, offset, littleEndian, 23, 4)
                    return offset + 4
                }

                Buffer.prototype.writeFloatLE = function writeFloatLE(value, offset, noAssert) {
                    return writeFloat(this, value, offset, true, noAssert)
                }

                Buffer.prototype.writeFloatBE = function writeFloatBE(value, offset, noAssert) {
                    return writeFloat(this, value, offset, false, noAssert)
                }

                function writeDouble(buf, value, offset, littleEndian, noAssert) {
                    value = +value
                    offset = offset >>> 0
                    if (!noAssert) {
                        checkIEEE754(buf, value, offset, 8, 1.7976931348623157E+308, -1.7976931348623157E+308)
                    }
                    ieee754.write(buf, value, offset, littleEndian, 52, 8)
                    return offset + 8
                }

                Buffer.prototype.writeDoubleLE = function writeDoubleLE(value, offset, noAssert) {
                    return writeDouble(this, value, offset, true, noAssert)
                }

                Buffer.prototype.writeDoubleBE = function writeDoubleBE(value, offset, noAssert) {
                    return writeDouble(this, value, offset, false, noAssert)
                }

                // copy(targetBuffer, targetStart=0, sourceStart=0, sourceEnd=buffer.length)
                Buffer.prototype.copy = function copy(target, targetStart, start, end) {
                    if (!Buffer.isBuffer(target)) throw new TypeError('argument should be a Buffer')
                    if (!start) start = 0
                    if (!end && end !== 0) end = this.length
                    if (targetStart >= target.length) targetStart = target.length
                    if (!targetStart) targetStart = 0
                    if (end > 0 && end < start) end = start

                    // Copy 0 bytes; we're done
                    if (end === start) return 0
                    if (target.length === 0 || this.length === 0) return 0

                    // Fatal error conditions
                    if (targetStart < 0) {
                        throw new RangeError('targetStart out of bounds')
                    }
                    if (start < 0 || start >= this.length) throw new RangeError('Index out of range')
                    if (end < 0) throw new RangeError('sourceEnd out of bounds')

                    // Are we oob?
                    if (end > this.length) end = this.length
                    if (target.length - targetStart < end - start) {
                        end = target.length - targetStart + start
                    }

                    var len = end - start

                    if (this === target && typeof Uint8Array.prototype.copyWithin === 'function') {
                        // Use built-in when available, missing from IE11
                        this.copyWithin(targetStart, start, end)
                    } else if (this === target && start < targetStart && targetStart < end) {
                        // descending copy from end
                        for (var i = len - 1; i >= 0; --i) {
                            target[i + targetStart] = this[i + start]
                        }
                    } else {
                        Uint8Array.prototype.set.call(
                            target,
                            this.subarray(start, end),
                            targetStart
                        )
                    }

                    return len
                }

                // Usage:
                //    buffer.fill(number[, offset[, end]])
                //    buffer.fill(buffer[, offset[, end]])
                //    buffer.fill(string[, offset[, end]][, encoding])
                Buffer.prototype.fill = function fill(val, start, end, encoding) {
                    // Handle string cases:
                    if (typeof val === 'string') {
                        if (typeof start === 'string') {
                            encoding = start
                            start = 0
                            end = this.length
                        } else if (typeof end === 'string') {
                            encoding = end
                            end = this.length
                        }
                        if (encoding !== undefined && typeof encoding !== 'string') {
                            throw new TypeError('encoding must be a string')
                        }
                        if (typeof encoding === 'string' && !Buffer.isEncoding(encoding)) {
                            throw new TypeError('Unknown encoding: ' + encoding)
                        }
                        if (val.length === 1) {
                            var code = val.charCodeAt(0)
                            if ((encoding === 'utf8' && code < 128) ||
                                encoding === 'latin1') {
                                // Fast path: If `val` fits into a single byte, use that numeric value.
                                val = code
                            }
                        }
                    } else if (typeof val === 'number') {
                        val = val & 255
                    }

                    // Invalid ranges are not set to a default, so can range check early.
                    if (start < 0 || this.length < start || this.length < end) {
                        throw new RangeError('Out of range index')
                    }

                    if (end <= start) {
                        return this
                    }

                    start = start >>> 0
                    end = end === undefined ? this.length : end >>> 0

                    if (!val) val = 0

                    var i
                    if (typeof val === 'number') {
                        for (i = start; i < end; ++i) {
                            this[i] = val
                        }
                    } else {
                        var bytes = Buffer.isBuffer(val) ?
                            val :
                            Buffer.from(val, encoding)
                        var len = bytes.length
                        if (len === 0) {
                            throw new TypeError('The value "' + val +
                                '" is invalid for argument "value"')
                        }
                        for (i = 0; i < end - start; ++i) {
                            this[i + start] = bytes[i % len]
                        }
                    }

                    return this
                }

                // HELPER FUNCTIONS
                // ================

                var INVALID_BASE64_RE = /[^+/0-9A-Za-z-_]/g

                function base64clean(str) {
                    // Node takes equal signs as end of the Base64 encoding
                    str = str.split('=')[0]
                    // Node strips out invalid characters like \n and \t from the string, base64-js does not
                    str = str.trim().replace(INVALID_BASE64_RE, '')
                    // Node converts strings with length < 2 to ''
                    if (str.length < 2) return ''
                    // Node allows for non-padded base64 strings (missing trailing ===), base64-js does not
                    while (str.length % 4 !== 0) {
                        str = str + '='
                    }
                    return str
                }

                function toHex(n) {
                    if (n < 16) return '0' + n.toString(16)
                    return n.toString(16)
                }

                function utf8ToBytes(string, units) {
                    units = units || Infinity
                    var codePoint
                    var length = string.length
                    var leadSurrogate = null
                    var bytes = []

                    for (var i = 0; i < length; ++i) {
                        codePoint = string.charCodeAt(i)

                        // is surrogate component
                        if (codePoint > 0xD7FF && codePoint < 0xE000) {
                            // last char was a lead
                            if (!leadSurrogate) {
                                // no lead yet
                                if (codePoint > 0xDBFF) {
                                    // unexpected trail
                                    if ((units -= 3) > -1) bytes.push(0xEF, 0xBF, 0xBD)
                                    continue
                                } else if (i + 1 === length) {
                                    // unpaired lead
                                    if ((units -= 3) > -1) bytes.push(0xEF, 0xBF, 0xBD)
                                    continue
                                }

                                // valid lead
                                leadSurrogate = codePoint

                                continue
                            }

                            // 2 leads in a row
                            if (codePoint < 0xDC00) {
                                if ((units -= 3) > -1) bytes.push(0xEF, 0xBF, 0xBD)
                                leadSurrogate = codePoint
                                continue
                            }

                            // valid surrogate pair
                            codePoint = (leadSurrogate - 0xD800 << 10 | codePoint - 0xDC00) + 0x10000
                        } else if (leadSurrogate) {
                            // valid bmp char, but last char was a lead
                            if ((units -= 3) > -1) bytes.push(0xEF, 0xBF, 0xBD)
                        }

                        leadSurrogate = null

                        // encode utf8
                        if (codePoint < 0x80) {
                            if ((units -= 1) < 0) break
                            bytes.push(codePoint)
                        } else if (codePoint < 0x800) {
                            if ((units -= 2) < 0) break
                            bytes.push(
                                codePoint >> 0x6 | 0xC0,
                                codePoint & 0x3F | 0x80
                            )
                        } else if (codePoint < 0x10000) {
                            if ((units -= 3) < 0) break
                            bytes.push(
                                codePoint >> 0xC | 0xE0,
                                codePoint >> 0x6 & 0x3F | 0x80,
                                codePoint & 0x3F | 0x80
                            )
                        } else if (codePoint < 0x110000) {
                            if ((units -= 4) < 0) break
                            bytes.push(
                                codePoint >> 0x12 | 0xF0,
                                codePoint >> 0xC & 0x3F | 0x80,
                                codePoint >> 0x6 & 0x3F | 0x80,
                                codePoint & 0x3F | 0x80
                            )
                        } else {
                            throw new Error('Invalid code point')
                        }
                    }

                    return bytes
                }

                function asciiToBytes(str) {
                    var byteArray = []
                    for (var i = 0; i < str.length; ++i) {
                        // Node's code seems to be doing this and not & 0x7F..
                        byteArray.push(str.charCodeAt(i) & 0xFF)
                    }
                    return byteArray
                }

                function utf16leToBytes(str, units) {
                    var c, hi, lo
                    var byteArray = []
                    for (var i = 0; i < str.length; ++i) {
                        if ((units -= 2) < 0) break

                        c = str.charCodeAt(i)
                        hi = c >> 8
                        lo = c % 256
                        byteArray.push(lo)
                        byteArray.push(hi)
                    }

                    return byteArray
                }

                function base64ToBytes(str) {
                    return base64.toByteArray(base64clean(str))
                }

                function blitBuffer(src, dst, offset, length) {
                    for (var i = 0; i < length; ++i) {
                        if ((i + offset >= dst.length) || (i >= src.length)) break
                        dst[i + offset] = src[i]
                    }
                    return i
                }

                // ArrayBuffer or Uint8Array objects from other contexts (i.e. iframes) do not pass
                // the `instanceof` check but they should be treated as of that type.
                // See: https://github.com/feross/buffer/issues/166
                function isInstance(obj, type) {
                    return obj instanceof type ||
                        (obj != null && obj.constructor != null && obj.constructor.name != null &&
                            obj.constructor.name === type.name)
                }

                function numberIsNaN(obj) {
                    // For IE11 support
                    return obj !== obj // eslint-disable-line no-self-compare
                }

            }).call(this)
        }).call(this, require("buffer").Buffer)
    }, {
        "base64-js": 1,
        "buffer": 3,
        "ieee754": 7
    }],
    4: [function(require, module, exports) {
        module.exports = {
            "100": "Continue",
            "101": "Switching Protocols",
            "102": "Processing",
            "200": "OK",
            "201": "Created",
            "202": "Accepted",
            "203": "Non-Authoritative Information",
            "204": "No Content",
            "205": "Reset Content",
            "206": "Partial Content",
            "207": "Multi-Status",
            "208": "Already Reported",
            "226": "IM Used",
            "300": "Multiple Choices",
            "301": "Moved Permanently",
            "302": "Found",
            "303": "See Other",
            "304": "Not Modified",
            "305": "Use Proxy",
            "307": "Temporary Redirect",
            "308": "Permanent Redirect",
            "400": "Bad Request",
            "401": "Unauthorized",
            "402": "Payment Required",
            "403": "Forbidden",
            "404": "Not Found",
            "405": "Method Not Allowed",
            "406": "Not Acceptable",
            "407": "Proxy Authentication Required",
            "408": "Request Timeout",
            "409": "Conflict",
            "410": "Gone",
            "411": "Length Required",
            "412": "Precondition Failed",
            "413": "Payload Too Large",
            "414": "URI Too Long",
            "415": "Unsupported Media Type",
            "416": "Range Not Satisfiable",
            "417": "Expectation Failed",
            "418": "I'm a teapot",
            "421": "Misdirected Request",
            "422": "Unprocessable Entity",
            "423": "Locked",
            "424": "Failed Dependency",
            "425": "Unordered Collection",
            "426": "Upgrade Required",
            "428": "Precondition Required",
            "429": "Too Many Requests",
            "431": "Request Header Fields Too Large",
            "451": "Unavailable For Legal Reasons",
            "500": "Internal Server Error",
            "501": "Not Implemented",
            "502": "Bad Gateway",
            "503": "Service Unavailable",
            "504": "Gateway Timeout",
            "505": "HTTP Version Not Supported",
            "506": "Variant Also Negotiates",
            "507": "Insufficient Storage",
            "508": "Loop Detected",
            "509": "Bandwidth Limit Exceeded",
            "510": "Not Extended",
            "511": "Network Authentication Required"
        }

    }, {}],
    5: [function(require, module, exports) {
        // Copyright Joyent, Inc. and other Node contributors.
        //
        // Permission is hereby granted, free of charge, to any person obtaining a
        // copy of this software and associated documentation files (the
        // "Software"), to deal in the Software without restriction, including
        // without limitation the rights to use, copy, modify, merge, publish,
        // distribute, sublicense, and/or sell copies of the Software, and to permit
        // persons to whom the Software is furnished to do so, subject to the
        // following conditions:
        //
        // The above copyright notice and this permission notice shall be included
        // in all copies or substantial portions of the Software.
        //
        // THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
        // OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
        // MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
        // NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
        // DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
        // OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
        // USE OR OTHER DEALINGS IN THE SOFTWARE.

        'use strict';

        var R = typeof Reflect === 'object' ? Reflect : null
        var ReflectApply = R && typeof R.apply === 'function' ?
            R.apply :
            function ReflectApply(target, receiver, args) {
                return Function.prototype.apply.call(target, receiver, args);
            }

        var ReflectOwnKeys
        if (R && typeof R.ownKeys === 'function') {
            ReflectOwnKeys = R.ownKeys
        } else if (Object.getOwnPropertySymbols) {
            ReflectOwnKeys = function ReflectOwnKeys(target) {
                return Object.getOwnPropertyNames(target)
                    .concat(Object.getOwnPropertySymbols(target));
            };
        } else {
            ReflectOwnKeys = function ReflectOwnKeys(target) {
                return Object.getOwnPropertyNames(target);
            };
        }

        function ProcessEmitWarning(warning) {
            if (console && console.warn) console.warn(warning);
        }

        var NumberIsNaN = Number.isNaN || function NumberIsNaN(value) {
            return value !== value;
        }

        function EventEmitter() {
            EventEmitter.init.call(this);
        }
        module.exports = EventEmitter;
        module.exports.once = once;

        // Backwards-compat with node 0.10.x
        EventEmitter.EventEmitter = EventEmitter;

        EventEmitter.prototype._events = undefined;
        EventEmitter.prototype._eventsCount = 0;
        EventEmitter.prototype._maxListeners = undefined;

        // By default EventEmitters will print a warning if more than 10 listeners are
        // added to it. This is a useful default which helps finding memory leaks.
        var defaultMaxListeners = 10;

        function checkListener(listener) {
            if (typeof listener !== 'function') {
                throw new TypeError('The "listener" argument must be of type Function. Received type ' + typeof listener);
            }
        }

        Object.defineProperty(EventEmitter, 'defaultMaxListeners', {
            enumerable: true,
            get: function() {
                return defaultMaxListeners;
            },
            set: function(arg) {
                if (typeof arg !== 'number' || arg < 0 || NumberIsNaN(arg)) {
                    throw new RangeError('The value of "defaultMaxListeners" is out of range. It must be a non-negative number. Received ' + arg + '.');
                }
                defaultMaxListeners = arg;
            }
        });

        EventEmitter.init = function() {

            if (this._events === undefined ||
                this._events === Object.getPrototypeOf(this)._events) {
                this._events = Object.create(null);
                this._eventsCount = 0;
            }

            this._maxListeners = this._maxListeners || undefined;
        };

        // Obviously not all Emitters should be limited to 10. This function allows
        // that to be increased. Set to zero for unlimited.
        EventEmitter.prototype.setMaxListeners = function setMaxListeners(n) {
            if (typeof n !== 'number' || n < 0 || NumberIsNaN(n)) {
                throw new RangeError('The value of "n" is out of range. It must be a non-negative number. Received ' + n + '.');
            }
            this._maxListeners = n;
            return this;
        };

        function _getMaxListeners(that) {
            if (that._maxListeners === undefined)
                return EventEmitter.defaultMaxListeners;
            return that._maxListeners;
        }

        EventEmitter.prototype.getMaxListeners = function getMaxListeners() {
            return _getMaxListeners(this);
        };

        EventEmitter.prototype.emit = function emit(type) {
            var args = [];
            for (var i = 1; i < arguments.length; i++) args.push(arguments[i]);
            var doError = (type === 'error');

            var events = this._events;
            if (events !== undefined)
                doError = (doError && events.error === undefined);
            else if (!doError)
                return false;

            // If there is no 'error' event listener then throw.
            if (doError) {
                var er;
                if (args.length > 0)
                    er = args[0];
                if (er instanceof Error) {
                    // Note: The comments on the `throw` lines are intentional, they show
                    // up in Node's output if this results in an unhandled exception.
                    throw er; // Unhandled 'error' event
                }
                // At least give some kind of context to the user
                var err = new Error('Unhandled error.' + (er ? ' (' + er.message + ')' : ''));
                err.context = er;
                throw err; // Unhandled 'error' event
            }

            var handler = events[type];

            if (handler === undefined)
                return false;

            if (typeof handler === 'function') {
                ReflectApply(handler, this, args);
            } else {
                var len = handler.length;
                var listeners = arrayClone(handler, len);
                for (var i = 0; i < len; ++i)
                    ReflectApply(listeners[i], this, args);
            }

            return true;
        };

        function _addListener(target, type, listener, prepend) {
            var m;
            var events;
            var existing;

            checkListener(listener);

            events = target._events;
            if (events === undefined) {
                events = target._events = Object.create(null);
                target._eventsCount = 0;
            } else {
                // To avoid recursion in the case that type === "newListener"! Before
                // adding it to the listeners, first emit "newListener".
                if (events.newListener !== undefined) {
                    target.emit('newListener', type,
                        listener.listener ? listener.listener : listener);

                    // Re-assign `events` because a newListener handler could have caused the
                    // this._events to be assigned to a new object
                    events = target._events;
                }
                existing = events[type];
            }

            if (existing === undefined) {
                // Optimize the case of one listener. Don't need the extra array object.
                existing = events[type] = listener;
                ++target._eventsCount;
            } else {
                if (typeof existing === 'function') {
                    // Adding the second element, need to change to array.
                    existing = events[type] =
                        prepend ? [listener, existing] : [existing, listener];
                    // If we've already got an array, just append.
                } else if (prepend) {
                    existing.unshift(listener);
                } else {
                    existing.push(listener);
                }

                // Check for listener leak
                m = _getMaxListeners(target);
                if (m > 0 && existing.length > m && !existing.warned) {
                    existing.warned = true;
                    // No error code for this since it is a Warning
                    // eslint-disable-next-line no-restricted-syntax
                    var w = new Error('Possible EventEmitter memory leak detected. ' +
                        existing.length + ' ' + String(type) + ' listeners ' +
                        'added. Use emitter.setMaxListeners() to ' +
                        'increase limit');
                    w.name = 'MaxListenersExceededWarning';
                    w.emitter = target;
                    w.type = type;
                    w.count = existing.length;
                    ProcessEmitWarning(w);
                }
            }

            return target;
        }

        EventEmitter.prototype.addListener = function addListener(type, listener) {
            return _addListener(this, type, listener, false);
        };

        EventEmitter.prototype.on = EventEmitter.prototype.addListener;

        EventEmitter.prototype.prependListener =
            function prependListener(type, listener) {
                return _addListener(this, type, listener, true);
            };

        function onceWrapper() {
            if (!this.fired) {
                this.target.removeListener(this.type, this.wrapFn);
                this.fired = true;
                if (arguments.length === 0)
                    return this.listener.call(this.target);
                return this.listener.apply(this.target, arguments);
            }
        }

        function _onceWrap(target, type, listener) {
            var state = {
                fired: false,
                wrapFn: undefined,
                target: target,
                type: type,
                listener: listener
            };
            var wrapped = onceWrapper.bind(state);
            wrapped.listener = listener;
            state.wrapFn = wrapped;
            return wrapped;
        }

        EventEmitter.prototype.once = function once(type, listener) {
            checkListener(listener);
            this.on(type, _onceWrap(this, type, listener));
            return this;
        };

        EventEmitter.prototype.prependOnceListener =
            function prependOnceListener(type, listener) {
                checkListener(listener);
                this.prependListener(type, _onceWrap(this, type, listener));
                return this;
            };

        // Emits a 'removeListener' event if and only if the listener was removed.
        EventEmitter.prototype.removeListener =
            function removeListener(type, listener) {
                var list, events, position, i, originalListener;

                checkListener(listener);

                events = this._events;
                if (events === undefined)
                    return this;

                list = events[type];
                if (list === undefined)
                    return this;

                if (list === listener || list.listener === listener) {
                    if (--this._eventsCount === 0)
                        this._events = Object.create(null);
                    else {
                        delete events[type];
                        if (events.removeListener)
                            this.emit('removeListener', type, list.listener || listener);
                    }
                } else if (typeof list !== 'function') {
                    position = -1;

                    for (i = list.length - 1; i >= 0; i--) {
                        if (list[i] === listener || list[i].listener === listener) {
                            originalListener = list[i].listener;
                            position = i;
                            break;
                        }
                    }

                    if (position < 0)
                        return this;

                    if (position === 0)
                        list.shift();
                    else {
                        spliceOne(list, position);
                    }

                    if (list.length === 1)
                        events[type] = list[0];

                    if (events.removeListener !== undefined)
                        this.emit('removeListener', type, originalListener || listener);
                }

                return this;
            };

        EventEmitter.prototype.off = EventEmitter.prototype.removeListener;

        EventEmitter.prototype.removeAllListeners =
            function removeAllListeners(type) {
                var listeners, events, i;

                events = this._events;
                if (events === undefined)
                    return this;

                // not listening for removeListener, no need to emit
                if (events.removeListener === undefined) {
                    if (arguments.length === 0) {
                        this._events = Object.create(null);
                        this._eventsCount = 0;
                    } else if (events[type] !== undefined) {
                        if (--this._eventsCount === 0)
                            this._events = Object.create(null);
                        else
                            delete events[type];
                    }
                    return this;
                }

                // emit removeListener for all listeners on all events
                if (arguments.length === 0) {
                    var keys = Object.keys(events);
                    var key;
                    for (i = 0; i < keys.length; ++i) {
                        key = keys[i];
                        if (key === 'removeListener') continue;
                        this.removeAllListeners(key);
                    }
                    this.removeAllListeners('removeListener');
                    this._events = Object.create(null);
                    this._eventsCount = 0;
                    return this;
                }

                listeners = events[type];

                if (typeof listeners === 'function') {
                    this.removeListener(type, listeners);
                } else if (listeners !== undefined) {
                    // LIFO order
                    for (i = listeners.length - 1; i >= 0; i--) {
                        this.removeListener(type, listeners[i]);
                    }
                }

                return this;
            };

        function _listeners(target, type, unwrap) {
            var events = target._events;

            if (events === undefined)
                return [];

            var evlistener = events[type];
            if (evlistener === undefined)
                return [];

            if (typeof evlistener === 'function')
                return unwrap ? [evlistener.listener || evlistener] : [evlistener];

            return unwrap ?
                unwrapListeners(evlistener) : arrayClone(evlistener, evlistener.length);
        }

        EventEmitter.prototype.listeners = function listeners(type) {
            return _listeners(this, type, true);
        };

        EventEmitter.prototype.rawListeners = function rawListeners(type) {
            return _listeners(this, type, false);
        };

        EventEmitter.listenerCount = function(emitter, type) {
            if (typeof emitter.listenerCount === 'function') {
                return emitter.listenerCount(type);
            } else {
                return listenerCount.call(emitter, type);
            }
        };

        EventEmitter.prototype.listenerCount = listenerCount;

        function listenerCount(type) {
            var events = this._events;

            if (events !== undefined) {
                var evlistener = events[type];

                if (typeof evlistener === 'function') {
                    return 1;
                } else if (evlistener !== undefined) {
                    return evlistener.length;
                }
            }

            return 0;
        }

        EventEmitter.prototype.eventNames = function eventNames() {
            return this._eventsCount > 0 ? ReflectOwnKeys(this._events) : [];
        };

        function arrayClone(arr, n) {
            var copy = new Array(n);
            for (var i = 0; i < n; ++i)
                copy[i] = arr[i];
            return copy;
        }

        function spliceOne(list, index) {
            for (; index + 1 < list.length; index++)
                list[index] = list[index + 1];
            list.pop();
        }

        function unwrapListeners(arr) {
            var ret = new Array(arr.length);
            for (var i = 0; i < ret.length; ++i) {
                ret[i] = arr[i].listener || arr[i];
            }
            return ret;
        }

        function once(emitter, name) {
            return new Promise(function(resolve, reject) {
                function errorListener(err) {
                    emitter.removeListener(name, resolver);
                    reject(err);
                }

                function resolver() {
                    if (typeof emitter.removeListener === 'function') {
                        emitter.removeListener('error', errorListener);
                    }
                    resolve([].slice.call(arguments));
                };

                eventTargetAgnosticAddListener(emitter, name, resolver, {
                    once: true
                });
                if (name !== 'error') {
                    addErrorHandlerIfEventEmitter(emitter, errorListener, {
                        once: true
                    });
                }
            });
        }

        function addErrorHandlerIfEventEmitter(emitter, handler, flags) {
            if (typeof emitter.on === 'function') {
                eventTargetAgnosticAddListener(emitter, 'error', handler, flags);
            }
        }

        function eventTargetAgnosticAddListener(emitter, name, listener, flags) {
            if (typeof emitter.on === 'function') {
                if (flags.once) {
                    emitter.once(name, listener);
                } else {
                    emitter.on(name, listener);
                }
            } else if (typeof emitter.addEventListener === 'function') {
                // EventTarget does not have `error` event semantics like Node
                // EventEmitters, we do not listen for `error` events here.
                emitter.addEventListener(name, function wrapListener(arg) {
                    // IE does not have builtin `{ once: true }` support so we
                    // have to do it manually.
                    if (flags.once) {
                        emitter.removeEventListener(name, wrapListener);
                    }
                    listener(arg);
                });
            } else {
                throw new TypeError('The "emitter" argument must be of type EventEmitter. Received type ' + typeof emitter);
            }
        }

    }, {}],
    6: [function(require, module, exports) {
        var http = require('http')
        var url = require('url')

        var https = module.exports

        for (var key in http) {
            if (http.hasOwnProperty(key)) https[key] = http[key]
        }

        https.request = function(params, cb) {
            params = validateParams(params)
            return http.request.call(this, params, cb)
        }

        https.get = function(params, cb) {
            params = validateParams(params)
            return http.get.call(this, params, cb)
        }

        function validateParams(params) {
            if (typeof params === 'string') {
                params = url.parse(params)
            }
            if (!params.protocol) {
                params.protocol = 'https:'
            }
            if (params.protocol !== 'https:') {
                throw new Error('Protocol "' + params.protocol + '" not supported. Expected "https:"')
            }
            return params
        }

    }, {
        "http": 30,
        "url": 51
    }],
    7: [function(require, module, exports) {
        /*! ieee754. BSD-3-Clause License. Feross Aboukhadijeh <https://feross.org/opensource> */
        exports.read = function(buffer, offset, isLE, mLen, nBytes) {
            var e, m
            var eLen = (nBytes * 8) - mLen - 1
            var eMax = (1 << eLen) - 1
            var eBias = eMax >> 1
            var nBits = -7
            var i = isLE ? (nBytes - 1) : 0
            var d = isLE ? -1 : 1
            var s = buffer[offset + i]

            i += d

            e = s & ((1 << (-nBits)) - 1)
            s >>= (-nBits)
            nBits += eLen
            for (; nBits > 0; e = (e * 256) + buffer[offset + i], i += d, nBits -= 8) {}

            m = e & ((1 << (-nBits)) - 1)
            e >>= (-nBits)
            nBits += mLen
            for (; nBits > 0; m = (m * 256) + buffer[offset + i], i += d, nBits -= 8) {}

            if (e === 0) {
                e = 1 - eBias
            } else if (e === eMax) {
                return m ? NaN : ((s ? -1 : 1) * Infinity)
            } else {
                m = m + Math.pow(2, mLen)
                e = e - eBias
            }
            return (s ? -1 : 1) * m * Math.pow(2, e - mLen)
        }

        exports.write = function(buffer, value, offset, isLE, mLen, nBytes) {
            var e, m, c
            var eLen = (nBytes * 8) - mLen - 1
            var eMax = (1 << eLen) - 1
            var eBias = eMax >> 1
            var rt = (mLen === 23 ? Math.pow(2, -24) - Math.pow(2, -77) : 0)
            var i = isLE ? 0 : (nBytes - 1)
            var d = isLE ? 1 : -1
            var s = value < 0 || (value === 0 && 1 / value < 0) ? 1 : 0

            value = Math.abs(value)

            if (isNaN(value) || value === Infinity) {
                m = isNaN(value) ? 1 : 0
                e = eMax
            } else {
                e = Math.floor(Math.log(value) / Math.LN2)
                if (value * (c = Math.pow(2, -e)) < 1) {
                    e--
                    c *= 2
                }
                if (e + eBias >= 1) {
                    value += rt / c
                } else {
                    value += rt * Math.pow(2, 1 - eBias)
                }
                if (value * c >= 2) {
                    e++
                    c /= 2
                }

                if (e + eBias >= eMax) {
                    m = 0
                    e = eMax
                } else if (e + eBias >= 1) {
                    m = ((value * c) - 1) * Math.pow(2, mLen)
                    e = e + eBias
                } else {
                    m = value * Math.pow(2, eBias - 1) * Math.pow(2, mLen)
                    e = 0
                }
            }

            for (; mLen >= 8; buffer[offset + i] = m & 0xff, i += d, m /= 256, mLen -= 8) {}

            e = (e << mLen) | m
            eLen += mLen
            for (; eLen > 0; buffer[offset + i] = e & 0xff, i += d, e /= 256, eLen -= 8) {}

            buffer[offset + i - d] |= s * 128
        }

    }, {}],
    8: [function(require, module, exports) {
        if (typeof Object.create === 'function') {
            // implementation from standard node.js 'util' module
            module.exports = function inherits(ctor, superCtor) {
                if (superCtor) {
                    ctor.super_ = superCtor
                    ctor.prototype = Object.create(superCtor.prototype, {
                        constructor: {
                            value: ctor,
                            enumerable: false,
                            writable: true,
                            configurable: true
                        }
                    })
                }
            };
        } else {
            // old school shim for old browsers
            module.exports = function inherits(ctor, superCtor) {
                if (superCtor) {
                    ctor.super_ = superCtor
                    var TempCtor = function() {}
                    TempCtor.prototype = superCtor.prototype
                    ctor.prototype = new TempCtor()
                    ctor.prototype.constructor = ctor
                }
            }
        }

    }, {}],
    9: [function(require, module, exports) {
        // shim for using process in browser
        var process = module.exports = {};

        // cached from whatever global is present so that test runners that stub it
        // don't break things.  But we need to wrap it in a try catch in case it is
        // wrapped in strict mode code which doesn't define any globals.  It's inside a
        // function because try/catches deoptimize in certain engines.

        var cachedSetTimeout;
        var cachedClearTimeout;

        function defaultSetTimout() {
            throw new Error('setTimeout has not been defined');
        }

        function defaultClearTimeout() {
            throw new Error('clearTimeout has not been defined');
        }
        (function() {
            try {
                if (typeof setTimeout === 'function') {
                    cachedSetTimeout = setTimeout;
                } else {
                    cachedSetTimeout = defaultSetTimout;
                }
            } catch (e) {
                cachedSetTimeout = defaultSetTimout;
            }
            try {
                if (typeof clearTimeout === 'function') {
                    cachedClearTimeout = clearTimeout;
                } else {
                    cachedClearTimeout = defaultClearTimeout;
                }
            } catch (e) {
                cachedClearTimeout = defaultClearTimeout;
            }
        }())

        function runTimeout(fun) {
            if (cachedSetTimeout === setTimeout) {
                //normal enviroments in sane situations
                return setTimeout(fun, 0);
            }
            // if setTimeout wasn't available but was latter defined
            if ((cachedSetTimeout === defaultSetTimout || !cachedSetTimeout) && setTimeout) {
                cachedSetTimeout = setTimeout;
                return setTimeout(fun, 0);
            }
            try {
                // when when somebody has screwed with setTimeout but no I.E. maddness
                return cachedSetTimeout(fun, 0);
            } catch (e) {
                try {
                    // When we are in I.E. but the script has been evaled so I.E. doesn't trust the global object when called normally
                    return cachedSetTimeout.call(null, fun, 0);
                } catch (e) {
                    // same as above but when it's a version of I.E. that must have the global object for 'this', hopfully our context correct otherwise it will throw a global error
                    return cachedSetTimeout.call(this, fun, 0);
                }
            }


        }

        function runClearTimeout(marker) {
            if (cachedClearTimeout === clearTimeout) {
                //normal enviroments in sane situations
                return clearTimeout(marker);
            }
            // if clearTimeout wasn't available but was latter defined
            if ((cachedClearTimeout === defaultClearTimeout || !cachedClearTimeout) && clearTimeout) {
                cachedClearTimeout = clearTimeout;
                return clearTimeout(marker);
            }
            try {
                // when when somebody has screwed with setTimeout but no I.E. maddness
                return cachedClearTimeout(marker);
            } catch (e) {
                try {
                    // When we are in I.E. but the script has been evaled so I.E. doesn't  trust the global object when called normally
                    return cachedClearTimeout.call(null, marker);
                } catch (e) {
                    // same as above but when it's a version of I.E. that must have the global object for 'this', hopfully our context correct otherwise it will throw a global error.
                    // Some versions of I.E. have different rules for clearTimeout vs setTimeout
                    return cachedClearTimeout.call(this, marker);
                }
            }



        }
        var queue = [];
        var draining = false;
        var currentQueue;
        var queueIndex = -1;

        function cleanUpNextTick() {
            if (!draining || !currentQueue) {
                return;
            }
            draining = false;
            if (currentQueue.length) {
                queue = currentQueue.concat(queue);
            } else {
                queueIndex = -1;
            }
            if (queue.length) {
                drainQueue();
            }
        }

        function drainQueue() {
            if (draining) {
                return;
            }
            var timeout = runTimeout(cleanUpNextTick);
            draining = true;

            var len = queue.length;
            while (len) {
                currentQueue = queue;
                queue = [];
                while (++queueIndex < len) {
                    if (currentQueue) {
                        currentQueue[queueIndex].run();
                    }
                }
                queueIndex = -1;
                len = queue.length;
            }
            currentQueue = null;
            draining = false;
            runClearTimeout(timeout);
        }

        process.nextTick = function(fun) {
            var args = new Array(arguments.length - 1);
            if (arguments.length > 1) {
                for (var i = 1; i < arguments.length; i++) {
                    args[i - 1] = arguments[i];
                }
            }
            queue.push(new Item(fun, args));
            if (queue.length === 1 && !draining) {
                runTimeout(drainQueue);
            }
        };

        // v8 likes predictible objects
        function Item(fun, array) {
            this.fun = fun;
            this.array = array;
        }
        Item.prototype.run = function() {
            this.fun.apply(null, this.array);
        };
        process.title = 'browser';
        process.browser = true;
        process.env = {};
        process.argv = [];
        process.version = ''; // empty string to avoid regexp issues
        process.versions = {};

        function noop() {}

        process.on = noop;
        process.addListener = noop;
        process.once = noop;
        process.off = noop;
        process.removeListener = noop;
        process.removeAllListeners = noop;
        process.emit = noop;
        process.prependListener = noop;
        process.prependOnceListener = noop;

        process.listeners = function(name) {
            return []
        }

        process.binding = function(name) {
            throw new Error('process.binding is not supported');
        };

        process.cwd = function() {
            return '/'
        };
        process.chdir = function(dir) {
            throw new Error('process.chdir is not supported');
        };
        process.umask = function() {
            return 0;
        };

    }, {}],
    10: [function(require, module, exports) {
        (function(global) {
            (function() {
                /*! https://mths.be/punycode v1.4.1 by @mathias */
                ;
                (function(root) {

                    /** Detect free variables */
                    var freeExports = typeof exports == 'object' && exports &&
                        !exports.nodeType && exports;
                    var freeModule = typeof module == 'object' && module &&
                        !module.nodeType && module;
                    var freeGlobal = typeof global == 'object' && global;
                    if (
                        freeGlobal.global === freeGlobal ||
                        freeGlobal.window === freeGlobal ||
                        freeGlobal.self === freeGlobal
                    ) {
                        root = freeGlobal;
                    }

                    /**
                     * The `punycode` object.
                     * @name punycode
                     * @type Object
                     */
                    var punycode,

                        /** Highest positive signed 32-bit float value */
                        maxInt = 2147483647, // aka. 0x7FFFFFFF or 2^31-1

                        /** Bootstring parameters */
                        base = 36,
                        tMin = 1,
                        tMax = 26,
                        skew = 38,
                        damp = 700,
                        initialBias = 72,
                        initialN = 128, // 0x80
                        delimiter = '-', // '\x2D'

                        /** Regular expressions */
                        regexPunycode = /^xn--/,
                        regexNonASCII = /[^\x20-\x7E]/, // unprintable ASCII chars + non-ASCII chars
                        regexSeparators = /[\x2E\u3002\uFF0E\uFF61]/g, // RFC 3490 separators

                        /** Error messages */
                        errors = {
                            'overflow': 'Overflow: input needs wider integers to process',
                            'not-basic': 'Illegal input >= 0x80 (not a basic code point)',
                            'invalid-input': 'Invalid input'
                        },

                        /** Convenience shortcuts */
                        baseMinusTMin = base - tMin,
                        floor = Math.floor,
                        stringFromCharCode = String.fromCharCode,

                        /** Temporary variable */
                        key;

                    /*--------------------------------------------------------------------------*/

                    /**
                     * A generic error utility function.
                     * @private
                     * @param {String} type The error type.
                     * @returns {Error} Throws a `RangeError` with the applicable error message.
                     */
                    function error(type) {
                        throw new RangeError(errors[type]);
                    }

                    /**
                     * A generic `Array#map` utility function.
                     * @private
                     * @param {Array} array The array to iterate over.
                     * @param {Function} callback The function that gets called for every array
                     * item.
                     * @returns {Array} A new array of values returned by the callback function.
                     */
                    function map(array, fn) {
                        var length = array.length;
                        var result = [];
                        while (length--) {
                            result[length] = fn(array[length]);
                        }
                        return result;
                    }

                    /**
                     * A simple `Array#map`-like wrapper to work with domain name strings or email
                     * addresses.
                     * @private
                     * @param {String} domain The domain name or email address.
                     * @param {Function} callback The function that gets called for every
                     * character.
                     * @returns {Array} A new string of characters returned by the callback
                     * function.
                     */
                    function mapDomain(string, fn) {
                        var parts = string.split('@');
                        var result = '';
                        if (parts.length > 1) {
                            // In email addresses, only the domain name should be punycoded. Leave
                            // the local part (i.e. everything up to `@`) intact.
                            result = parts[0] + '@';
                            string = parts[1];
                        }
                        // Avoid `split(regex)` for IE8 compatibility. See #17.
                        string = string.replace(regexSeparators, '\x2E');
                        var labels = string.split('.');
                        var encoded = map(labels, fn).join('.');
                        return result + encoded;
                    }

                    /**
                     * Creates an array containing the numeric code points of each Unicode
                     * character in the string. While JavaScript uses UCS-2 internally,
                     * this function will convert a pair of surrogate halves (each of which
                     * UCS-2 exposes as separate characters) into a single code point,
                     * matching UTF-16.
                     * @see `punycode.ucs2.encode`
                     * @see <https://mathiasbynens.be/notes/javascript-encoding>
                     * @memberOf punycode.ucs2
                     * @name decode
                     * @param {String} string The Unicode input string (UCS-2).
                     * @returns {Array} The new array of code points.
                     */
                    function ucs2decode(string) {
                        var output = [],
                            counter = 0,
                            length = string.length,
                            value,
                            extra;
                        while (counter < length) {
                            value = string.charCodeAt(counter++);
                            if (value >= 0xD800 && value <= 0xDBFF && counter < length) {
                                // high surrogate, and there is a next character
                                extra = string.charCodeAt(counter++);
                                if ((extra & 0xFC00) == 0xDC00) { // low surrogate
                                    output.push(((value & 0x3FF) << 10) + (extra & 0x3FF) + 0x10000);
                                } else {
                                    // unmatched surrogate; only append this code unit, in case the next
                                    // code unit is the high surrogate of a surrogate pair
                                    output.push(value);
                                    counter--;
                                }
                            } else {
                                output.push(value);
                            }
                        }
                        return output;
                    }

                    /**
                     * Creates a string based on an array of numeric code points.
                     * @see `punycode.ucs2.decode`
                     * @memberOf punycode.ucs2
                     * @name encode
                     * @param {Array} codePoints The array of numeric code points.
                     * @returns {String} The new Unicode string (UCS-2).
                     */
                    function ucs2encode(array) {
                        return map(array, function(value) {
                            var output = '';
                            if (value > 0xFFFF) {
                                value -= 0x10000;
                                output += stringFromCharCode(value >>> 10 & 0x3FF | 0xD800);
                                value = 0xDC00 | value & 0x3FF;
                            }
                            output += stringFromCharCode(value);
                            return output;
                        }).join('');
                    }

                    /**
                     * Converts a basic code point into a digit/integer.
                     * @see `digitToBasic()`
                     * @private
                     * @param {Number} codePoint The basic numeric code point value.
                     * @returns {Number} The numeric value of a basic code point (for use in
                     * representing integers) in the range `0` to `base - 1`, or `base` if
                     * the code point does not represent a value.
                     */
                    function basicToDigit(codePoint) {
                        if (codePoint - 48 < 10) {
                            return codePoint - 22;
                        }
                        if (codePoint - 65 < 26) {
                            return codePoint - 65;
                        }
                        if (codePoint - 97 < 26) {
                            return codePoint - 97;
                        }
                        return base;
                    }

                    /**
                     * Converts a digit/integer into a basic code point.
                     * @see `basicToDigit()`
                     * @private
                     * @param {Number} digit The numeric value of a basic code point.
                     * @returns {Number} The basic code point whose value (when used for
                     * representing integers) is `digit`, which needs to be in the range
                     * `0` to `base - 1`. If `flag` is non-zero, the uppercase form is
                     * used; else, the lowercase form is used. The behavior is undefined
                     * if `flag` is non-zero and `digit` has no uppercase form.
                     */
                    function digitToBasic(digit, flag) {
                        //  0..25 map to ASCII a..z or A..Z
                        // 26..35 map to ASCII 0..9
                        return digit + 22 + 75 * (digit < 26) - ((flag != 0) << 5);
                    }

                    /**
                     * Bias adaptation function as per section 3.4 of RFC 3492.
                     * https://tools.ietf.org/html/rfc3492#section-3.4
                     * @private
                     */
                    function adapt(delta, numPoints, firstTime) {
                        var k = 0;
                        delta = firstTime ? floor(delta / damp) : delta >> 1;
                        delta += floor(delta / numPoints);
                        for ( /* no initialization */ ; delta > baseMinusTMin * tMax >> 1; k += base) {
                            delta = floor(delta / baseMinusTMin);
                        }
                        return floor(k + (baseMinusTMin + 1) * delta / (delta + skew));
                    }

                    /**
                     * Converts a Punycode string of ASCII-only symbols to a string of Unicode
                     * symbols.
                     * @memberOf punycode
                     * @param {String} input The Punycode string of ASCII-only symbols.
                     * @returns {String} The resulting string of Unicode symbols.
                     */
                    function decode(input) {
                        // Don't use UCS-2
                        var output = [],
                            inputLength = input.length,
                            out,
                            i = 0,
                            n = initialN,
                            bias = initialBias,
                            basic,
                            j,
                            index,
                            oldi,
                            w,
                            k,
                            digit,
                            t,
                            /** Cached calculation results */
                            baseMinusT;

                        // Handle the basic code points: let `basic` be the number of input code
                        // points before the last delimiter, or `0` if there is none, then copy
                        // the first basic code points to the output.

                        basic = input.lastIndexOf(delimiter);
                        if (basic < 0) {
                            basic = 0;
                        }

                        for (j = 0; j < basic; ++j) {
                            // if it's not a basic code point
                            if (input.charCodeAt(j) >= 0x80) {
                                error('not-basic');
                            }
                            output.push(input.charCodeAt(j));
                        }

                        // Main decoding loop: start just after the last delimiter if any basic code
                        // points were copied; start at the beginning otherwise.

                        for (index = basic > 0 ? basic + 1 : 0; index < inputLength; /* no final expression */ ) {

                            // `index` is the index of the next character to be consumed.
                            // Decode a generalized variable-length integer into `delta`,
                            // which gets added to `i`. The overflow checking is easier
                            // if we increase `i` as we go, then subtract off its starting
                            // value at the end to obtain `delta`.
                            for (oldi = i, w = 1, k = base; /* no condition */ ; k += base) {

                                if (index >= inputLength) {
                                    error('invalid-input');
                                }

                                digit = basicToDigit(input.charCodeAt(index++));

                                if (digit >= base || digit > floor((maxInt - i) / w)) {
                                    error('overflow');
                                }

                                i += digit * w;
                                t = k <= bias ? tMin : (k >= bias + tMax ? tMax : k - bias);

                                if (digit < t) {
                                    break;
                                }

                                baseMinusT = base - t;
                                if (w > floor(maxInt / baseMinusT)) {
                                    error('overflow');
                                }

                                w *= baseMinusT;

                            }

                            out = output.length + 1;
                            bias = adapt(i - oldi, out, oldi == 0);

                            // `i` was supposed to wrap around from `out` to `0`,
                            // incrementing `n` each time, so we'll fix that now:
                            if (floor(i / out) > maxInt - n) {
                                error('overflow');
                            }

                            n += floor(i / out);
                            i %= out;

                            // Insert `n` at position `i` of the output
                            output.splice(i++, 0, n);

                        }

                        return ucs2encode(output);
                    }

                    /**
                     * Converts a string of Unicode symbols (e.g. a domain name label) to a
                     * Punycode string of ASCII-only symbols.
                     * @memberOf punycode
                     * @param {String} input The string of Unicode symbols.
                     * @returns {String} The resulting Punycode string of ASCII-only symbols.
                     */
                    function encode(input) {
                        var n,
                            delta,
                            handledCPCount,
                            basicLength,
                            bias,
                            j,
                            m,
                            q,
                            k,
                            t,
                            currentValue,
                            output = [],
                            /** `inputLength` will hold the number of code points in `input`. */
                            inputLength,
                            /** Cached calculation results */
                            handledCPCountPlusOne,
                            baseMinusT,
                            qMinusT;

                        // Convert the input in UCS-2 to Unicode
                        input = ucs2decode(input);

                        // Cache the length
                        inputLength = input.length;

                        // Initialize the state
                        n = initialN;
                        delta = 0;
                        bias = initialBias;

                        // Handle the basic code points
                        for (j = 0; j < inputLength; ++j) {
                            currentValue = input[j];
                            if (currentValue < 0x80) {
                                output.push(stringFromCharCode(currentValue));
                            }
                        }

                        handledCPCount = basicLength = output.length;

                        // `handledCPCount` is the number of code points that have been handled;
                        // `basicLength` is the number of basic code points.

                        // Finish the basic string - if it is not empty - with a delimiter
                        if (basicLength) {
                            output.push(delimiter);
                        }

                        // Main encoding loop:
                        while (handledCPCount < inputLength) {

                            // All non-basic code points < n have been handled already. Find the next
                            // larger one:
                            for (m = maxInt, j = 0; j < inputLength; ++j) {
                                currentValue = input[j];
                                if (currentValue >= n && currentValue < m) {
                                    m = currentValue;
                                }
                            }

                            // Increase `delta` enough to advance the decoder's <n,i> state to <m,0>,
                            // but guard against overflow
                            handledCPCountPlusOne = handledCPCount + 1;
                            if (m - n > floor((maxInt - delta) / handledCPCountPlusOne)) {
                                error('overflow');
                            }

                            delta += (m - n) * handledCPCountPlusOne;
                            n = m;

                            for (j = 0; j < inputLength; ++j) {
                                currentValue = input[j];

                                if (currentValue < n && ++delta > maxInt) {
                                    error('overflow');
                                }

                                if (currentValue == n) {
                                    // Represent delta as a generalized variable-length integer
                                    for (q = delta, k = base; /* no condition */ ; k += base) {
                                        t = k <= bias ? tMin : (k >= bias + tMax ? tMax : k - bias);
                                        if (q < t) {
                                            break;
                                        }
                                        qMinusT = q - t;
                                        baseMinusT = base - t;
                                        output.push(
                                            stringFromCharCode(digitToBasic(t + qMinusT % baseMinusT, 0))
                                        );
                                        q = floor(qMinusT / baseMinusT);
                                    }

                                    output.push(stringFromCharCode(digitToBasic(q, 0)));
                                    bias = adapt(delta, handledCPCountPlusOne, handledCPCount == basicLength);
                                    delta = 0;
                                    ++handledCPCount;
                                }
                            }

                            ++delta;
                            ++n;

                        }
                        return output.join('');
                    }

                    /**
                     * Converts a Punycode string representing a domain name or an email address
                     * to Unicode. Only the Punycoded parts of the input will be converted, i.e.
                     * it doesn't matter if you call it on a string that has already been
                     * converted to Unicode.
                     * @memberOf punycode
                     * @param {String} input The Punycoded domain name or email address to
                     * convert to Unicode.
                     * @returns {String} The Unicode representation of the given Punycode
                     * string.
                     */
                    function toUnicode(input) {
                        return mapDomain(input, function(string) {
                            return regexPunycode.test(string) ?
                                decode(string.slice(4).toLowerCase()) :
                                string;
                        });
                    }

                    /**
                     * Converts a Unicode string representing a domain name or an email address to
                     * Punycode. Only the non-ASCII parts of the domain name will be converted,
                     * i.e. it doesn't matter if you call it with a domain that's already in
                     * ASCII.
                     * @memberOf punycode
                     * @param {String} input The domain name or email address to convert, as a
                     * Unicode string.
                     * @returns {String} The Punycode representation of the given domain name or
                     * email address.
                     */
                    function toASCII(input) {
                        return mapDomain(input, function(string) {
                            return regexNonASCII.test(string) ?
                                'xn--' + encode(string) :
                                string;
                        });
                    }

                    /*--------------------------------------------------------------------------*/

                    /** Define the public API */
                    punycode = {
                        /**
                         * A string representing the current Punycode.js version number.
                         * @memberOf punycode
                         * @type String
                         */
                        'version': '1.4.1',
                        /**
                         * An object of methods to convert from JavaScript's internal character
                         * representation (UCS-2) to Unicode code points, and back.
                         * @see <https://mathiasbynens.be/notes/javascript-encoding>
                         * @memberOf punycode
                         * @type Object
                         */
                        'ucs2': {
                            'decode': ucs2decode,
                            'encode': ucs2encode
                        },
                        'decode': decode,
                        'encode': encode,
                        'toASCII': toASCII,
                        'toUnicode': toUnicode
                    };

                    /** Expose `punycode` */
                    // Some AMD build optimizers, like r.js, check for specific condition patterns
                    // like the following:
                    if (
                        typeof define == 'function' &&
                        typeof define.amd == 'object' &&
                        define.amd
                    ) {
                        define('punycode', function() {
                            return punycode;
                        });
                    } else if (freeExports && freeModule) {
                        if (module.exports == freeExports) {
                            // in Node.js, io.js, or RingoJS v0.8.0+
                            freeModule.exports = punycode;
                        } else {
                            // in Narwhal or RingoJS v0.7.0-
                            for (key in punycode) {
                                punycode.hasOwnProperty(key) && (freeExports[key] = punycode[key]);
                            }
                        }
                    } else {
                        // in Rhino or a web browser
                        root.punycode = punycode;
                    }

                }(this));

            }).call(this)
        }).call(this, typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
    }, {}],
    11: [function(require, module, exports) {
        // Copyright Joyent, Inc. and other Node contributors.
        //
        // Permission is hereby granted, free of charge, to any person obtaining a
        // copy of this software and associated documentation files (the
        // "Software"), to deal in the Software without restriction, including
        // without limitation the rights to use, copy, modify, merge, publish,
        // distribute, sublicense, and/or sell copies of the Software, and to permit
        // persons to whom the Software is furnished to do so, subject to the
        // following conditions:
        //
        // The above copyright notice and this permission notice shall be included
        // in all copies or substantial portions of the Software.
        //
        // THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
        // OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
        // MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
        // NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
        // DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
        // OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
        // USE OR OTHER DEALINGS IN THE SOFTWARE.

        'use strict';

        // If obj.hasOwnProperty has been overridden, then calling
        // obj.hasOwnProperty(prop) will break.
        // See: https://github.com/joyent/node/issues/1707
        function hasOwnProperty(obj, prop) {
            return Object.prototype.hasOwnProperty.call(obj, prop);
        }

        module.exports = function(qs, sep, eq, options) {
            sep = sep || '&';
            eq = eq || '=';
            var obj = {};

            if (typeof qs !== 'string' || qs.length === 0) {
                return obj;
            }

            var regexp = /\+/g;
            qs = qs.split(sep);

            var maxKeys = 1000;
            if (options && typeof options.maxKeys === 'number') {
                maxKeys = options.maxKeys;
            }

            var len = qs.length;
            // maxKeys <= 0 means that we should not limit keys count
            if (maxKeys > 0 && len > maxKeys) {
                len = maxKeys;
            }

            for (var i = 0; i < len; ++i) {
                var x = qs[i].replace(regexp, '%20'),
                    idx = x.indexOf(eq),
                    kstr, vstr, k, v;

                if (idx >= 0) {
                    kstr = x.substr(0, idx);
                    vstr = x.substr(idx + 1);
                } else {
                    kstr = x;
                    vstr = '';
                }

                k = decodeURIComponent(kstr);
                v = decodeURIComponent(vstr);

                if (!hasOwnProperty(obj, k)) {
                    obj[k] = v;
                } else if (isArray(obj[k])) {
                    obj[k].push(v);
                } else {
                    obj[k] = [obj[k], v];
                }
            }

            return obj;
        };

        var isArray = Array.isArray || function(xs) {
            return Object.prototype.toString.call(xs) === '[object Array]';
        };

    }, {}],
    12: [function(require, module, exports) {
        // Copyright Joyent, Inc. and other Node contributors.
        //
        // Permission is hereby granted, free of charge, to any person obtaining a
        // copy of this software and associated documentation files (the
        // "Software"), to deal in the Software without restriction, including
        // without limitation the rights to use, copy, modify, merge, publish,
        // distribute, sublicense, and/or sell copies of the Software, and to permit
        // persons to whom the Software is furnished to do so, subject to the
        // following conditions:
        //
        // The above copyright notice and this permission notice shall be included
        // in all copies or substantial portions of the Software.
        //
        // THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
        // OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
        // MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
        // NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
        // DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
        // OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
        // USE OR OTHER DEALINGS IN THE SOFTWARE.

        'use strict';

        var stringifyPrimitive = function(v) {
            switch (typeof v) {
                case 'string':
                    return v;

                case 'boolean':
                    return v ? 'true' : 'false';

                case 'number':
                    return isFinite(v) ? v : '';

                default:
                    return '';
            }
        };

        module.exports = function(obj, sep, eq, name) {
            sep = sep || '&';
            eq = eq || '=';
            if (obj === null) {
                obj = undefined;
            }

            if (typeof obj === 'object') {
                return map(objectKeys(obj), function(k) {
                    var ks = encodeURIComponent(stringifyPrimitive(k)) + eq;
                    if (isArray(obj[k])) {
                        return map(obj[k], function(v) {
                            return ks + encodeURIComponent(stringifyPrimitive(v));
                        }).join(sep);
                    } else {
                        return ks + encodeURIComponent(stringifyPrimitive(obj[k]));
                    }
                }).join(sep);

            }

            if (!name) return '';
            return encodeURIComponent(stringifyPrimitive(name)) + eq +
                encodeURIComponent(stringifyPrimitive(obj));
        };

        var isArray = Array.isArray || function(xs) {
            return Object.prototype.toString.call(xs) === '[object Array]';
        };

        function map(xs, f) {
            if (xs.map) return xs.map(f);
            var res = [];
            for (var i = 0; i < xs.length; i++) {
                res.push(f(xs[i], i));
            }
            return res;
        }

        var objectKeys = Object.keys || function(obj) {
            var res = [];
            for (var key in obj) {
                if (Object.prototype.hasOwnProperty.call(obj, key)) res.push(key);
            }
            return res;
        };

    }, {}],
    13: [function(require, module, exports) {
        'use strict';

        exports.decode = exports.parse = require('./decode');
        exports.encode = exports.stringify = require('./encode');

    }, {
        "./decode": 11,
        "./encode": 12
    }],
    14: [function(require, module, exports) {
        /*! safe-buffer. MIT License. Feross Aboukhadijeh <https://feross.org/opensource> */
        /* eslint-disable node/no-deprecated-api */
        var buffer = require('buffer')
        var Buffer = buffer.Buffer

        // alternative to using Object.keys for old browsers
        function copyProps(src, dst) {
            for (var key in src) {
                dst[key] = src[key]
            }
        }
        if (Buffer.from && Buffer.alloc && Buffer.allocUnsafe && Buffer.allocUnsafeSlow) {
            module.exports = buffer
        } else {
            // Copy properties from require('buffer')
            copyProps(buffer, exports)
            exports.Buffer = SafeBuffer
        }

        function SafeBuffer(arg, encodingOrOffset, length) {
            return Buffer(arg, encodingOrOffset, length)
        }

        SafeBuffer.prototype = Object.create(Buffer.prototype)

        // Copy static methods from Buffer
        copyProps(Buffer, SafeBuffer)

        SafeBuffer.from = function(arg, encodingOrOffset, length) {
            if (typeof arg === 'number') {
                throw new TypeError('Argument must not be a number')
            }
            return Buffer(arg, encodingOrOffset, length)
        }

        SafeBuffer.alloc = function(size, fill, encoding) {
            if (typeof size !== 'number') {
                throw new TypeError('Argument must be a number')
            }
            var buf = Buffer(size)
            if (fill !== undefined) {
                if (typeof encoding === 'string') {
                    buf.fill(fill, encoding)
                } else {
                    buf.fill(fill)
                }
            } else {
                buf.fill(0)
            }
            return buf
        }

        SafeBuffer.allocUnsafe = function(size) {
            if (typeof size !== 'number') {
                throw new TypeError('Argument must be a number')
            }
            return Buffer(size)
        }

        SafeBuffer.allocUnsafeSlow = function(size) {
            if (typeof size !== 'number') {
                throw new TypeError('Argument must be a number')
            }
            return buffer.SlowBuffer(size)
        }

    }, {
        "buffer": 3
    }],
    15: [function(require, module, exports) {
        // Copyright Joyent, Inc. and other Node contributors.
        //
        // Permission is hereby granted, free of charge, to any person obtaining a
        // copy of this software and associated documentation files (the
        // "Software"), to deal in the Software without restriction, including
        // without limitation the rights to use, copy, modify, merge, publish,
        // distribute, sublicense, and/or sell copies of the Software, and to permit
        // persons to whom the Software is furnished to do so, subject to the
        // following conditions:
        //
        // The above copyright notice and this permission notice shall be included
        // in all copies or substantial portions of the Software.
        //
        // THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
        // OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
        // MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
        // NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
        // DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
        // OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
        // USE OR OTHER DEALINGS IN THE SOFTWARE.

        module.exports = Stream;

        var EE = require('events').EventEmitter;
        var inherits = require('inherits');

        inherits(Stream, EE);
        Stream.Readable = require('readable-stream/lib/_stream_readable.js');
        Stream.Writable = require('readable-stream/lib/_stream_writable.js');
        Stream.Duplex = require('readable-stream/lib/_stream_duplex.js');
        Stream.Transform = require('readable-stream/lib/_stream_transform.js');
        Stream.PassThrough = require('readable-stream/lib/_stream_passthrough.js');
        Stream.finished = require('readable-stream/lib/internal/streams/end-of-stream.js')
        Stream.pipeline = require('readable-stream/lib/internal/streams/pipeline.js')

        // Backwards-compat with node 0.4.x
        Stream.Stream = Stream;



        // old-style streams.  Note that the pipe method (the only relevant
        // part of this class) is overridden in the Readable class.

        function Stream() {
            EE.call(this);
        }

        Stream.prototype.pipe = function(dest, options) {
            var source = this;

            function ondata(chunk) {
                if (dest.writable) {
                    if (false === dest.write(chunk) && source.pause) {
                        source.pause();
                    }
                }
            }

            source.on('data', ondata);

            function ondrain() {
                if (source.readable && source.resume) {
                    source.resume();
                }
            }

            dest.on('drain', ondrain);

            // If the 'end' option is not supplied, dest.end() will be called when
            // source gets the 'end' or 'close' events.  Only dest.end() once.
            if (!dest._isStdio && (!options || options.end !== false)) {
                source.on('end', onend);
                source.on('close', onclose);
            }

            var didOnEnd = false;

            function onend() {
                if (didOnEnd) return;
                didOnEnd = true;

                dest.end();
            }


            function onclose() {
                if (didOnEnd) return;
                didOnEnd = true;

                if (typeof dest.destroy === 'function') dest.destroy();
            }

            // don't leave dangling pipes when there are errors.
            function onerror(er) {
                cleanup();
                if (EE.listenerCount(this, 'error') === 0) {
                    throw er; // Unhandled stream error in pipe.
                }
            }

            source.on('error', onerror);
            dest.on('error', onerror);

            // remove all the event listeners that were added.
            function cleanup() {
                source.removeListener('data', ondata);
                dest.removeListener('drain', ondrain);

                source.removeListener('end', onend);
                source.removeListener('close', onclose);

                source.removeListener('error', onerror);
                dest.removeListener('error', onerror);

                source.removeListener('end', cleanup);
                source.removeListener('close', cleanup);

                dest.removeListener('close', cleanup);
            }

            source.on('end', cleanup);
            source.on('close', cleanup);

            dest.on('close', cleanup);

            dest.emit('pipe', source);

            // Allow for unix-like usage: A.pipe(B).pipe(C)
            return dest;
        };

    }, {
        "events": 5,
        "inherits": 8,
        "readable-stream/lib/_stream_duplex.js": 17,
        "readable-stream/lib/_stream_passthrough.js": 18,
        "readable-stream/lib/_stream_readable.js": 19,
        "readable-stream/lib/_stream_transform.js": 20,
        "readable-stream/lib/_stream_writable.js": 21,
        "readable-stream/lib/internal/streams/end-of-stream.js": 25,
        "readable-stream/lib/internal/streams/pipeline.js": 27
    }],
    16: [function(require, module, exports) {
        'use strict';

        function _inheritsLoose(subClass, superClass) {
            subClass.prototype = Object.create(superClass.prototype);
            subClass.prototype.constructor = subClass;
            subClass.__proto__ = superClass;
        }

        var codes = {};

        function createErrorType(code, message, Base) {
            if (!Base) {
                Base = Error;
            }

            function getMessage(arg1, arg2, arg3) {
                if (typeof message === 'string') {
                    return message;
                } else {
                    return message(arg1, arg2, arg3);
                }
            }

            var NodeError =
                /*#__PURE__*/
                function(_Base) {
                    _inheritsLoose(NodeError, _Base);

                    function NodeError(arg1, arg2, arg3) {
                        return _Base.call(this, getMessage(arg1, arg2, arg3)) || this;
                    }

                    return NodeError;
                }(Base);

            NodeError.prototype.name = Base.name;
            NodeError.prototype.code = code;
            codes[code] = NodeError;
        } // https://github.com/nodejs/node/blob/v10.8.0/lib/internal/errors.js


        function oneOf(expected, thing) {
            if (Array.isArray(expected)) {
                var len = expected.length;
                expected = expected.map(function(i) {
                    return String(i);
                });

                if (len > 2) {
                    return "one of ".concat(thing, " ").concat(expected.slice(0, len - 1).join(', '), ", or ") + expected[len - 1];
                } else if (len === 2) {
                    return "one of ".concat(thing, " ").concat(expected[0], " or ").concat(expected[1]);
                } else {
                    return "of ".concat(thing, " ").concat(expected[0]);
                }
            } else {
                return "of ".concat(thing, " ").concat(String(expected));
            }
        } // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/startsWith


        function startsWith(str, search, pos) {
            return str.substr(!pos || pos < 0 ? 0 : +pos, search.length) === search;
        } // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/endsWith


        function endsWith(str, search, this_len) {
            if (this_len === undefined || this_len > str.length) {
                this_len = str.length;
            }

            return str.substring(this_len - search.length, this_len) === search;
        } // https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/includes


        function includes(str, search, start) {
            if (typeof start !== 'number') {
                start = 0;
            }

            if (start + search.length > str.length) {
                return false;
            } else {
                return str.indexOf(search, start) !== -1;
            }
        }

        createErrorType('ERR_INVALID_OPT_VALUE', function(name, value) {
            return 'The value "' + value + '" is invalid for option "' + name + '"';
        }, TypeError);
        createErrorType('ERR_INVALID_ARG_TYPE', function(name, expected, actual) {
            // determiner: 'must be' or 'must not be'
            var determiner;

            if (typeof expected === 'string' && startsWith(expected, 'not ')) {
                determiner = 'must not be';
                expected = expected.replace(/^not /, '');
            } else {
                determiner = 'must be';
            }

            var msg;

            if (endsWith(name, ' argument')) {
                // For cases like 'first argument'
                msg = "The ".concat(name, " ").concat(determiner, " ").concat(oneOf(expected, 'type'));
            } else {
                var type = includes(name, '.') ? 'property' : 'argument';
                msg = "The \"".concat(name, "\" ").concat(type, " ").concat(determiner, " ").concat(oneOf(expected, 'type'));
            }

            msg += ". Received type ".concat(typeof actual);
            return msg;
        }, TypeError);
        createErrorType('ERR_STREAM_PUSH_AFTER_EOF', 'stream.push() after EOF');
        createErrorType('ERR_METHOD_NOT_IMPLEMENTED', function(name) {
            return 'The ' + name + ' method is not implemented';
        });
        createErrorType('ERR_STREAM_PREMATURE_CLOSE', 'Premature close');
        createErrorType('ERR_STREAM_DESTROYED', function(name) {
            return 'Cannot call ' + name + ' after a stream was destroyed';
        });
        createErrorType('ERR_MULTIPLE_CALLBACK', 'Callback called multiple times');
        createErrorType('ERR_STREAM_CANNOT_PIPE', 'Cannot pipe, not readable');
        createErrorType('ERR_STREAM_WRITE_AFTER_END', 'write after end');
        createErrorType('ERR_STREAM_NULL_VALUES', 'May not write null values to stream', TypeError);
        createErrorType('ERR_UNKNOWN_ENCODING', function(arg) {
            return 'Unknown encoding: ' + arg;
        }, TypeError);
        createErrorType('ERR_STREAM_UNSHIFT_AFTER_END_EVENT', 'stream.unshift() after end event');
        module.exports.codes = codes;

    }, {}],
    17: [function(require, module, exports) {
        (function(process) {
            (function() {
                // Copyright Joyent, Inc. and other Node contributors.
                //
                // Permission is hereby granted, free of charge, to any person obtaining a
                // copy of this software and associated documentation files (the
                // "Software"), to deal in the Software without restriction, including
                // without limitation the rights to use, copy, modify, merge, publish,
                // distribute, sublicense, and/or sell copies of the Software, and to permit
                // persons to whom the Software is furnished to do so, subject to the
                // following conditions:
                //
                // The above copyright notice and this permission notice shall be included
                // in all copies or substantial portions of the Software.
                //
                // THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
                // OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
                // MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
                // NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
                // DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
                // OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
                // USE OR OTHER DEALINGS IN THE SOFTWARE.

                // a duplex stream is just a stream that is both readable and writable.
                // Since JS doesn't have multiple prototypal inheritance, this class
                // prototypally inherits from Readable, and then parasitically from
                // Writable.

                'use strict';

                /*<replacement>*/
                var objectKeys = Object.keys || function(obj) {
                    var keys = [];
                    for (var key in obj) keys.push(key);
                    return keys;
                };
                /*</replacement>*/

                module.exports = Duplex;
                const Readable = require('./_stream_readable');
                const Writable = require('./_stream_writable');
                require('inherits')(Duplex, Readable); {
                    // Allow the keys array to be GC'ed.
                    const keys = objectKeys(Writable.prototype);
                    for (var v = 0; v < keys.length; v++) {
                        const method = keys[v];
                        if (!Duplex.prototype[method]) Duplex.prototype[method] = Writable.prototype[method];
                    }
                }

                function Duplex(options) {
                    if (!(this instanceof Duplex)) return new Duplex(options);
                    Readable.call(this, options);
                    Writable.call(this, options);
                    this.allowHalfOpen = true;
                    if (options) {
                        if (options.readable === false) this.readable = false;
                        if (options.writable === false) this.writable = false;
                        if (options.allowHalfOpen === false) {
                            this.allowHalfOpen = false;
                            this.once('end', onend);
                        }
                    }
                }
                Object.defineProperty(Duplex.prototype, 'writableHighWaterMark', {
                    // making it explicit this property is not enumerable
                    // because otherwise some prototype manipulation in
                    // userland will fail
                    enumerable: false,
                    get() {
                        return this._writableState.highWaterMark;
                    }
                });
                Object.defineProperty(Duplex.prototype, 'writableBuffer', {
                    // making it explicit this property is not enumerable
                    // because otherwise some prototype manipulation in
                    // userland will fail
                    enumerable: false,
                    get: function get() {
                        return this._writableState && this._writableState.getBuffer();
                    }
                });
                Object.defineProperty(Duplex.prototype, 'writableLength', {
                    // making it explicit this property is not enumerable
                    // because otherwise some prototype manipulation in
                    // userland will fail
                    enumerable: false,
                    get() {
                        return this._writableState.length;
                    }
                });

                // the no-half-open enforcer
                function onend() {
                    // If the writable side ended, then we're ok.
                    if (this._writableState.ended) return;

                    // no more data can be written.
                    // But allow more writes to happen in this tick.
                    process.nextTick(onEndNT, this);
                }

                function onEndNT(self) {
                    self.end();
                }
                Object.defineProperty(Duplex.prototype, 'destroyed', {
                    // making it explicit this property is not enumerable
                    // because otherwise some prototype manipulation in
                    // userland will fail
                    enumerable: false,
                    get() {
                        if (this._readableState === undefined || this._writableState === undefined) {
                            return false;
                        }
                        return this._readableState.destroyed && this._writableState.destroyed;
                    },
                    set(value) {
                        // we ignore the value if the stream
                        // has not been initialized yet
                        if (this._readableState === undefined || this._writableState === undefined) {
                            return;
                        }

                        // backward compatibility, the user is explicitly
                        // managing destroyed
                        this._readableState.destroyed = value;
                        this._writableState.destroyed = value;
                    }
                });
            }).call(this)
        }).call(this, require('_process'))
    }, {
        "./_stream_readable": 19,
        "./_stream_writable": 21,
        "_process": 9,
        "inherits": 8
    }],
    18: [function(require, module, exports) {
        // Copyright Joyent, Inc. and other Node contributors.
        //
        // Permission is hereby granted, free of charge, to any person obtaining a
        // copy of this software and associated documentation files (the
        // "Software"), to deal in the Software without restriction, including
        // without limitation the rights to use, copy, modify, merge, publish,
        // distribute, sublicense, and/or sell copies of the Software, and to permit
        // persons to whom the Software is furnished to do so, subject to the
        // following conditions:
        //
        // The above copyright notice and this permission notice shall be included
        // in all copies or substantial portions of the Software.
        //
        // THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
        // OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
        // MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
        // NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
        // DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
        // OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
        // USE OR OTHER DEALINGS IN THE SOFTWARE.

        // a passthrough stream.
        // basically just the most minimal sort of Transform stream.
        // Every written chunk gets output as-is.

        'use strict';

        module.exports = PassThrough;
        const Transform = require('./_stream_transform');
        require('inherits')(PassThrough, Transform);

        function PassThrough(options) {
            if (!(this instanceof PassThrough)) return new PassThrough(options);
            Transform.call(this, options);
        }
        PassThrough.prototype._transform = function(chunk, encoding, cb) {
            cb(null, chunk);
        };
    }, {
        "./_stream_transform": 20,
        "inherits": 8
    }],
    19: [function(require, module, exports) {
        (function(process, global) {
            (function() {
                // Copyright Joyent, Inc. and other Node contributors.
                //
                // Permission is hereby granted, free of charge, to any person obtaining a
                // copy of this software and associated documentation files (the
                // "Software"), to deal in the Software without restriction, including
                // without limitation the rights to use, copy, modify, merge, publish,
                // distribute, sublicense, and/or sell copies of the Software, and to permit
                // persons to whom the Software is furnished to do so, subject to the
                // following conditions:
                //
                // The above copyright notice and this permission notice shall be included
                // in all copies or substantial portions of the Software.
                //
                // THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
                // OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
                // MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
                // NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
                // DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
                // OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
                // USE OR OTHER DEALINGS IN THE SOFTWARE.

                'use strict';

                module.exports = Readable;

                /*<replacement>*/
                var Duplex;
                /*</replacement>*/

                Readable.ReadableState = ReadableState;

                /*<replacement>*/
                const EE = require('events').EventEmitter;
                var EElistenerCount = function EElistenerCount(emitter, type) {
                    return emitter.listeners(type).length;
                };
                /*</replacement>*/

                /*<replacement>*/
                var Stream = require('./internal/streams/stream');
                /*</replacement>*/

                const Buffer = require('buffer').Buffer;
                const OurUint8Array = (typeof global !== 'undefined' ? global : typeof window !== 'undefined' ? window : typeof self !== 'undefined' ? self : {}).Uint8Array || function() {};

                function _uint8ArrayToBuffer(chunk) {
                    return Buffer.from(chunk);
                }

                function _isUint8Array(obj) {
                    return Buffer.isBuffer(obj) || obj instanceof OurUint8Array;
                }

                /*<replacement>*/
                const debugUtil = require('util');
                let debug;
                if (debugUtil && debugUtil.debuglog) {
                    debug = debugUtil.debuglog('stream');
                } else {
                    debug = function debug() {};
                }
                /*</replacement>*/

                const BufferList = require('./internal/streams/buffer_list');
                const destroyImpl = require('./internal/streams/destroy');
                const _require = require('./internal/streams/state'),
                    getHighWaterMark = _require.getHighWaterMark;
                const _require$codes = require('../errors').codes,
                    ERR_INVALID_ARG_TYPE = _require$codes.ERR_INVALID_ARG_TYPE,
                    ERR_STREAM_PUSH_AFTER_EOF = _require$codes.ERR_STREAM_PUSH_AFTER_EOF,
                    ERR_METHOD_NOT_IMPLEMENTED = _require$codes.ERR_METHOD_NOT_IMPLEMENTED,
                    ERR_STREAM_UNSHIFT_AFTER_END_EVENT = _require$codes.ERR_STREAM_UNSHIFT_AFTER_END_EVENT;

                // Lazy loaded to improve the startup performance.
                let StringDecoder;
                let createReadableStreamAsyncIterator;
                let from;
                require('inherits')(Readable, Stream);
                const errorOrDestroy = destroyImpl.errorOrDestroy;
                const kProxyEvents = ['error', 'close', 'destroy', 'pause', 'resume'];

                function prependListener(emitter, event, fn) {
                    // Sadly this is not cacheable as some libraries bundle their own
                    // event emitter implementation with them.
                    if (typeof emitter.prependListener === 'function') return emitter.prependListener(event, fn);

                    // This is a hack to make sure that our error handler is attached before any
                    // userland ones.  NEVER DO THIS. This is here only because this code needs
                    // to continue to work with older versions of Node.js that do not include
                    // the prependListener() method. The goal is to eventually remove this hack.
                    if (!emitter._events || !emitter._events[event]) emitter.on(event, fn);
                    else if (Array.isArray(emitter._events[event])) emitter._events[event].unshift(fn);
                    else emitter._events[event] = [fn, emitter._events[event]];
                }

                function ReadableState(options, stream, isDuplex) {
                    Duplex = Duplex || require('./_stream_duplex');
                    options = options || {};

                    // Duplex streams are both readable and writable, but share
                    // the same options object.
                    // However, some cases require setting options to different
                    // values for the readable and the writable sides of the duplex stream.
                    // These options can be provided separately as readableXXX and writableXXX.
                    if (typeof isDuplex !== 'boolean') isDuplex = stream instanceof Duplex;

                    // object stream flag. Used to make read(n) ignore n and to
                    // make all the buffer merging and length checks go away
                    this.objectMode = !!options.objectMode;
                    if (isDuplex) this.objectMode = this.objectMode || !!options.readableObjectMode;

                    // the point at which it stops calling _read() to fill the buffer
                    // Note: 0 is a valid value, means "don't call _read preemptively ever"
                    this.highWaterMark = getHighWaterMark(this, options, 'readableHighWaterMark', isDuplex);

                    // A linked list is used to store data chunks instead of an array because the
                    // linked list can remove elements from the beginning faster than
                    // array.shift()
                    this.buffer = new BufferList();
                    this.length = 0;
                    this.pipes = null;
                    this.pipesCount = 0;
                    this.flowing = null;
                    this.ended = false;
                    this.endEmitted = false;
                    this.reading = false;

                    // a flag to be able to tell if the event 'readable'/'data' is emitted
                    // immediately, or on a later tick.  We set this to true at first, because
                    // any actions that shouldn't happen until "later" should generally also
                    // not happen before the first read call.
                    this.sync = true;

                    // whenever we return null, then we set a flag to say
                    // that we're awaiting a 'readable' event emission.
                    this.needReadable = false;
                    this.emittedReadable = false;
                    this.readableListening = false;
                    this.resumeScheduled = false;
                    this.paused = true;

                    // Should close be emitted on destroy. Defaults to true.
                    this.emitClose = options.emitClose !== false;

                    // Should .destroy() be called after 'end' (and potentially 'finish')
                    this.autoDestroy = !!options.autoDestroy;

                    // has it been destroyed
                    this.destroyed = false;

                    // Crypto is kind of old and crusty.  Historically, its default string
                    // encoding is 'binary' so we have to make this configurable.
                    // Everything else in the universe uses 'utf8', though.
                    this.defaultEncoding = options.defaultEncoding || 'utf8';

                    // the number of writers that are awaiting a drain event in .pipe()s
                    this.awaitDrain = 0;

                    // if true, a maybeReadMore has been scheduled
                    this.readingMore = false;
                    this.decoder = null;
                    this.encoding = null;
                    if (options.encoding) {
                        if (!StringDecoder) StringDecoder = require('string_decoder/').StringDecoder;
                        this.decoder = new StringDecoder(options.encoding);
                        this.encoding = options.encoding;
                    }
                }

                function Readable(options) {
                    Duplex = Duplex || require('./_stream_duplex');
                    if (!(this instanceof Readable)) return new Readable(options);

                    // Checking for a Stream.Duplex instance is faster here instead of inside
                    // the ReadableState constructor, at least with V8 6.5
                    const isDuplex = this instanceof Duplex;
                    this._readableState = new ReadableState(options, this, isDuplex);

                    // legacy
                    this.readable = true;
                    if (options) {
                        if (typeof options.read === 'function') this._read = options.read;
                        if (typeof options.destroy === 'function') this._destroy = options.destroy;
                    }
                    Stream.call(this);
                }
                Object.defineProperty(Readable.prototype, 'destroyed', {
                    // making it explicit this property is not enumerable
                    // because otherwise some prototype manipulation in
                    // userland will fail
                    enumerable: false,
                    get() {
                        if (this._readableState === undefined) {
                            return false;
                        }
                        return this._readableState.destroyed;
                    },
                    set(value) {
                        // we ignore the value if the stream
                        // has not been initialized yet
                        if (!this._readableState) {
                            return;
                        }

                        // backward compatibility, the user is explicitly
                        // managing destroyed
                        this._readableState.destroyed = value;
                    }
                });
                Readable.prototype.destroy = destroyImpl.destroy;
                Readable.prototype._undestroy = destroyImpl.undestroy;
                Readable.prototype._destroy = function(err, cb) {
                    cb(err);
                };

                // Manually shove something into the read() buffer.
                // This returns true if the highWaterMark has not been hit yet,
                // similar to how Writable.write() returns true if you should
                // write() some more.
                Readable.prototype.push = function(chunk, encoding) {
                    var state = this._readableState;
                    var skipChunkCheck;
                    if (!state.objectMode) {
                        if (typeof chunk === 'string') {
                            encoding = encoding || state.defaultEncoding;
                            if (encoding !== state.encoding) {
                                chunk = Buffer.from(chunk, encoding);
                                encoding = '';
                            }
                            skipChunkCheck = true;
                        }
                    } else {
                        skipChunkCheck = true;
                    }
                    return readableAddChunk(this, chunk, encoding, false, skipChunkCheck);
                };

                // Unshift should *always* be something directly out of read()
                Readable.prototype.unshift = function(chunk) {
                    return readableAddChunk(this, chunk, null, true, false);
                };

                function readableAddChunk(stream, chunk, encoding, addToFront, skipChunkCheck) {
                    debug('readableAddChunk', chunk);
                    var state = stream._readableState;
                    if (chunk === null) {
                        state.reading = false;
                        onEofChunk(stream, state);
                    } else {
                        var er;
                        if (!skipChunkCheck) er = chunkInvalid(state, chunk);
                        if (er) {
                            errorOrDestroy(stream, er);
                        } else if (state.objectMode || chunk && chunk.length > 0) {
                            if (typeof chunk !== 'string' && !state.objectMode && Object.getPrototypeOf(chunk) !== Buffer.prototype) {
                                chunk = _uint8ArrayToBuffer(chunk);
                            }
                            if (addToFront) {
                                if (state.endEmitted) errorOrDestroy(stream, new ERR_STREAM_UNSHIFT_AFTER_END_EVENT());
                                else addChunk(stream, state, chunk, true);
                            } else if (state.ended) {
                                errorOrDestroy(stream, new ERR_STREAM_PUSH_AFTER_EOF());
                            } else if (state.destroyed) {
                                return false;
                            } else {
                                state.reading = false;
                                if (state.decoder && !encoding) {
                                    chunk = state.decoder.write(chunk);
                                    if (state.objectMode || chunk.length !== 0) addChunk(stream, state, chunk, false);
                                    else maybeReadMore(stream, state);
                                } else {
                                    addChunk(stream, state, chunk, false);
                                }
                            }
                        } else if (!addToFront) {
                            state.reading = false;
                            maybeReadMore(stream, state);
                        }
                    }

                    // We can push more data if we are below the highWaterMark.
                    // Also, if we have no data yet, we can stand some more bytes.
                    // This is to work around cases where hwm=0, such as the repl.
                    return !state.ended && (state.length < state.highWaterMark || state.length === 0);
                }

                function addChunk(stream, state, chunk, addToFront) {
                    if (state.flowing && state.length === 0 && !state.sync) {
                        state.awaitDrain = 0;
                        stream.emit('data', chunk);
                    } else {
                        // update the buffer info.
                        state.length += state.objectMode ? 1 : chunk.length;
                        if (addToFront) state.buffer.unshift(chunk);
                        else state.buffer.push(chunk);
                        if (state.needReadable) emitReadable(stream);
                    }
                    maybeReadMore(stream, state);
                }

                function chunkInvalid(state, chunk) {
                    var er;
                    if (!_isUint8Array(chunk) && typeof chunk !== 'string' && chunk !== undefined && !state.objectMode) {
                        er = new ERR_INVALID_ARG_TYPE('chunk', ['string', 'Buffer', 'Uint8Array'], chunk);
                    }
                    return er;
                }
                Readable.prototype.isPaused = function() {
                    return this._readableState.flowing === false;
                };

                // backwards compatibility.
                Readable.prototype.setEncoding = function(enc) {
                    if (!StringDecoder) StringDecoder = require('string_decoder/').StringDecoder;
                    const decoder = new StringDecoder(enc);
                    this._readableState.decoder = decoder;
                    // If setEncoding(null), decoder.encoding equals utf8
                    this._readableState.encoding = this._readableState.decoder.encoding;

                    // Iterate over current buffer to convert already stored Buffers:
                    let p = this._readableState.buffer.head;
                    let content = '';
                    while (p !== null) {
                        content += decoder.write(p.data);
                        p = p.next;
                    }
                    this._readableState.buffer.clear();
                    if (content !== '') this._readableState.buffer.push(content);
                    this._readableState.length = content.length;
                    return this;
                };

                // Don't raise the hwm > 1GB
                const MAX_HWM = 0x40000000;

                function computeNewHighWaterMark(n) {
                    if (n >= MAX_HWM) {
                        // TODO(ronag): Throw ERR_VALUE_OUT_OF_RANGE.
                        n = MAX_HWM;
                    } else {
                        // Get the next highest power of 2 to prevent increasing hwm excessively in
                        // tiny amounts
                        n--;
                        n |= n >>> 1;
                        n |= n >>> 2;
                        n |= n >>> 4;
                        n |= n >>> 8;
                        n |= n >>> 16;
                        n++;
                    }
                    return n;
                }

                // This function is designed to be inlinable, so please take care when making
                // changes to the function body.
                function howMuchToRead(n, state) {
                    if (n <= 0 || state.length === 0 && state.ended) return 0;
                    if (state.objectMode) return 1;
                    if (n !== n) {
                        // Only flow one buffer at a time
                        if (state.flowing && state.length) return state.buffer.head.data.length;
                        else return state.length;
                    }
                    // If we're asking for more than the current hwm, then raise the hwm.
                    if (n > state.highWaterMark) state.highWaterMark = computeNewHighWaterMark(n);
                    if (n <= state.length) return n;
                    // Don't have enough
                    if (!state.ended) {
                        state.needReadable = true;
                        return 0;
                    }
                    return state.length;
                }

                // you can override either this method, or the async _read(n) below.
                Readable.prototype.read = function(n) {
                    debug('read', n);
                    n = parseInt(n, 10);
                    var state = this._readableState;
                    var nOrig = n;
                    if (n !== 0) state.emittedReadable = false;

                    // if we're doing read(0) to trigger a readable event, but we
                    // already have a bunch of data in the buffer, then just trigger
                    // the 'readable' event and move on.
                    if (n === 0 && state.needReadable && ((state.highWaterMark !== 0 ? state.length >= state.highWaterMark : state.length > 0) || state.ended)) {
                        debug('read: emitReadable', state.length, state.ended);
                        if (state.length === 0 && state.ended) endReadable(this);
                        else emitReadable(this);
                        return null;
                    }
                    n = howMuchToRead(n, state);

                    // if we've ended, and we're now clear, then finish it up.
                    if (n === 0 && state.ended) {
                        if (state.length === 0) endReadable(this);
                        return null;
                    }

                    // All the actual chunk generation logic needs to be
                    // *below* the call to _read.  The reason is that in certain
                    // synthetic stream cases, such as passthrough streams, _read
                    // may be a completely synchronous operation which may change
                    // the state of the read buffer, providing enough data when
                    // before there was *not* enough.
                    //
                    // So, the steps are:
                    // 1. Figure out what the state of things will be after we do
                    // a read from the buffer.
                    //
                    // 2. If that resulting state will trigger a _read, then call _read.
                    // Note that this may be asynchronous, or synchronous.  Yes, it is
                    // deeply ugly to write APIs this way, but that still doesn't mean
                    // that the Readable class should behave improperly, as streams are
                    // designed to be sync/async agnostic.
                    // Take note if the _read call is sync or async (ie, if the read call
                    // has returned yet), so that we know whether or not it's safe to emit
                    // 'readable' etc.
                    //
                    // 3. Actually pull the requested chunks out of the buffer and return.

                    // if we need a readable event, then we need to do some reading.
                    var doRead = state.needReadable;
                    debug('need readable', doRead);

                    // if we currently have less than the highWaterMark, then also read some
                    if (state.length === 0 || state.length - n < state.highWaterMark) {
                        doRead = true;
                        debug('length less than watermark', doRead);
                    }

                    // however, if we've ended, then there's no point, and if we're already
                    // reading, then it's unnecessary.
                    if (state.ended || state.reading) {
                        doRead = false;
                        debug('reading or ended', doRead);
                    } else if (doRead) {
                        debug('do read');
                        state.reading = true;
                        state.sync = true;
                        // if the length is currently zero, then we *need* a readable event.
                        if (state.length === 0) state.needReadable = true;
                        // call internal read method
                        this._read(state.highWaterMark);
                        state.sync = false;
                        // If _read pushed data synchronously, then `reading` will be false,
                        // and we need to re-evaluate how much data we can return to the user.
                        if (!state.reading) n = howMuchToRead(nOrig, state);
                    }
                    var ret;
                    if (n > 0) ret = fromList(n, state);
                    else ret = null;
                    if (ret === null) {
                        state.needReadable = state.length <= state.highWaterMark;
                        n = 0;
                    } else {
                        state.length -= n;
                        state.awaitDrain = 0;
                    }
                    if (state.length === 0) {
                        // If we have nothing in the buffer, then we want to know
                        // as soon as we *do* get something into the buffer.
                        if (!state.ended) state.needReadable = true;

                        // If we tried to read() past the EOF, then emit end on the next tick.
                        if (nOrig !== n && state.ended) endReadable(this);
                    }
                    if (ret !== null) this.emit('data', ret);
                    return ret;
                };

                function onEofChunk(stream, state) {
                    debug('onEofChunk');
                    if (state.ended) return;
                    if (state.decoder) {
                        var chunk = state.decoder.end();
                        if (chunk && chunk.length) {
                            state.buffer.push(chunk);
                            state.length += state.objectMode ? 1 : chunk.length;
                        }
                    }
                    state.ended = true;
                    if (state.sync) {
                        // if we are sync, wait until next tick to emit the data.
                        // Otherwise we risk emitting data in the flow()
                        // the readable code triggers during a read() call
                        emitReadable(stream);
                    } else {
                        // emit 'readable' now to make sure it gets picked up.
                        state.needReadable = false;
                        if (!state.emittedReadable) {
                            state.emittedReadable = true;
                            emitReadable_(stream);
                        }
                    }
                }

                // Don't emit readable right away in sync mode, because this can trigger
                // another read() call => stack overflow.  This way, it might trigger
                // a nextTick recursion warning, but that's not so bad.
                function emitReadable(stream) {
                    var state = stream._readableState;
                    debug('emitReadable', state.needReadable, state.emittedReadable);
                    state.needReadable = false;
                    if (!state.emittedReadable) {
                        debug('emitReadable', state.flowing);
                        state.emittedReadable = true;
                        process.nextTick(emitReadable_, stream);
                    }
                }

                function emitReadable_(stream) {
                    var state = stream._readableState;
                    debug('emitReadable_', state.destroyed, state.length, state.ended);
                    if (!state.destroyed && (state.length || state.ended)) {
                        stream.emit('readable');
                        state.emittedReadable = false;
                    }

                    // The stream needs another readable event if
                    // 1. It is not flowing, as the flow mechanism will take
                    //    care of it.
                    // 2. It is not ended.
                    // 3. It is below the highWaterMark, so we can schedule
                    //    another readable later.
                    state.needReadable = !state.flowing && !state.ended && state.length <= state.highWaterMark;
                    flow(stream);
                }

                // at this point, the user has presumably seen the 'readable' event,
                // and called read() to consume some data.  that may have triggered
                // in turn another _read(n) call, in which case reading = true if
                // it's in progress.
                // However, if we're not ended, or reading, and the length < hwm,
                // then go ahead and try to read some more preemptively.
                function maybeReadMore(stream, state) {
                    if (!state.readingMore) {
                        state.readingMore = true;
                        process.nextTick(maybeReadMore_, stream, state);
                    }
                }

                function maybeReadMore_(stream, state) {
                    // Attempt to read more data if we should.
                    //
                    // The conditions for reading more data are (one of):
                    // - Not enough data buffered (state.length < state.highWaterMark). The loop
                    //   is responsible for filling the buffer with enough data if such data
                    //   is available. If highWaterMark is 0 and we are not in the flowing mode
                    //   we should _not_ attempt to buffer any extra data. We'll get more data
                    //   when the stream consumer calls read() instead.
                    // - No data in the buffer, and the stream is in flowing mode. In this mode
                    //   the loop below is responsible for ensuring read() is called. Failing to
                    //   call read here would abort the flow and there's no other mechanism for
                    //   continuing the flow if the stream consumer has just subscribed to the
                    //   'data' event.
                    //
                    // In addition to the above conditions to keep reading data, the following
                    // conditions prevent the data from being read:
                    // - The stream has ended (state.ended).
                    // - There is already a pending 'read' operation (state.reading). This is a
                    //   case where the the stream has called the implementation defined _read()
                    //   method, but they are processing the call asynchronously and have _not_
                    //   called push() with new data. In this case we skip performing more
                    //   read()s. The execution ends in this method again after the _read() ends
                    //   up calling push() with more data.
                    while (!state.reading && !state.ended && (state.length < state.highWaterMark || state.flowing && state.length === 0)) {
                        const len = state.length;
                        debug('maybeReadMore read 0');
                        stream.read(0);
                        if (len === state.length)
                            // didn't get any data, stop spinning.
                            break;
                    }
                    state.readingMore = false;
                }

                // abstract method.  to be overridden in specific implementation classes.
                // call cb(er, data) where data is <= n in length.
                // for virtual (non-string, non-buffer) streams, "length" is somewhat
                // arbitrary, and perhaps not very meaningful.
                Readable.prototype._read = function(n) {
                    errorOrDestroy(this, new ERR_METHOD_NOT_IMPLEMENTED('_read()'));
                };
                Readable.prototype.pipe = function(dest, pipeOpts) {
                    var src = this;
                    var state = this._readableState;
                    switch (state.pipesCount) {
                        case 0:
                            state.pipes = dest;
                            break;
                        case 1:
                            state.pipes = [state.pipes, dest];
                            break;
                        default:
                            state.pipes.push(dest);
                            break;
                    }
                    state.pipesCount += 1;
                    debug('pipe count=%d opts=%j', state.pipesCount, pipeOpts);
                    var doEnd = (!pipeOpts || pipeOpts.end !== false) && dest !== process.stdout && dest !== process.stderr;
                    var endFn = doEnd ? onend : unpipe;
                    if (state.endEmitted) process.nextTick(endFn);
                    else src.once('end', endFn);
                    dest.on('unpipe', onunpipe);

                    function onunpipe(readable, unpipeInfo) {
                        debug('onunpipe');
                        if (readable === src) {
                            if (unpipeInfo && unpipeInfo.hasUnpiped === false) {
                                unpipeInfo.hasUnpiped = true;
                                cleanup();
                            }
                        }
                    }

                    function onend() {
                        debug('onend');
                        dest.end();
                    }

                    // when the dest drains, it reduces the awaitDrain counter
                    // on the source.  This would be more elegant with a .once()
                    // handler in flow(), but adding and removing repeatedly is
                    // too slow.
                    var ondrain = pipeOnDrain(src);
                    dest.on('drain', ondrain);
                    var cleanedUp = false;

                    function cleanup() {
                        debug('cleanup');
                        // cleanup event handlers once the pipe is broken
                        dest.removeListener('close', onclose);
                        dest.removeListener('finish', onfinish);
                        dest.removeListener('drain', ondrain);
                        dest.removeListener('error', onerror);
                        dest.removeListener('unpipe', onunpipe);
                        src.removeListener('end', onend);
                        src.removeListener('end', unpipe);
                        src.removeListener('data', ondata);
                        cleanedUp = true;

                        // if the reader is waiting for a drain event from this
                        // specific writer, then it would cause it to never start
                        // flowing again.
                        // So, if this is awaiting a drain, then we just call it now.
                        // If we don't know, then assume that we are waiting for one.
                        if (state.awaitDrain && (!dest._writableState || dest._writableState.needDrain)) ondrain();
                    }
                    src.on('data', ondata);

                    function ondata(chunk) {
                        debug('ondata');
                        var ret = dest.write(chunk);
                        debug('dest.write', ret);
                        if (ret === false) {
                            // If the user unpiped during `dest.write()`, it is possible
                            // to get stuck in a permanently paused state if that write
                            // also returned false.
                            // => Check whether `dest` is still a piping destination.
                            if ((state.pipesCount === 1 && state.pipes === dest || state.pipesCount > 1 && indexOf(state.pipes, dest) !== -1) && !cleanedUp) {
                                debug('false write response, pause', state.awaitDrain);
                                state.awaitDrain++;
                            }
                            src.pause();
                        }
                    }

                    // if the dest has an error, then stop piping into it.
                    // however, don't suppress the throwing behavior for this.
                    function onerror(er) {
                        debug('onerror', er);
                        unpipe();
                        dest.removeListener('error', onerror);
                        if (EElistenerCount(dest, 'error') === 0) errorOrDestroy(dest, er);
                    }

                    // Make sure our error handler is attached before userland ones.
                    prependListener(dest, 'error', onerror);

                    // Both close and finish should trigger unpipe, but only once.
                    function onclose() {
                        dest.removeListener('finish', onfinish);
                        unpipe();
                    }
                    dest.once('close', onclose);

                    function onfinish() {
                        debug('onfinish');
                        dest.removeListener('close', onclose);
                        unpipe();
                    }
                    dest.once('finish', onfinish);

                    function unpipe() {
                        debug('unpipe');
                        src.unpipe(dest);
                    }

                    // tell the dest that it's being piped to
                    dest.emit('pipe', src);

                    // start the flow if it hasn't been started already.
                    if (!state.flowing) {
                        debug('pipe resume');
                        src.resume();
                    }
                    return dest;
                };

                function pipeOnDrain(src) {
                    return function pipeOnDrainFunctionResult() {
                        var state = src._readableState;
                        debug('pipeOnDrain', state.awaitDrain);
                        if (state.awaitDrain) state.awaitDrain--;
                        if (state.awaitDrain === 0 && EElistenerCount(src, 'data')) {
                            state.flowing = true;
                            flow(src);
                        }
                    };
                }
                Readable.prototype.unpipe = function(dest) {
                    var state = this._readableState;
                    var unpipeInfo = {
                        hasUnpiped: false
                    };

                    // if we're not piping anywhere, then do nothing.
                    if (state.pipesCount === 0) return this;

                    // just one destination.  most common case.
                    if (state.pipesCount === 1) {
                        // passed in one, but it's not the right one.
                        if (dest && dest !== state.pipes) return this;
                        if (!dest) dest = state.pipes;

                        // got a match.
                        state.pipes = null;
                        state.pipesCount = 0;
                        state.flowing = false;
                        if (dest) dest.emit('unpipe', this, unpipeInfo);
                        return this;
                    }

                    // slow case. multiple pipe destinations.

                    if (!dest) {
                        // remove all.
                        var dests = state.pipes;
                        var len = state.pipesCount;
                        state.pipes = null;
                        state.pipesCount = 0;
                        state.flowing = false;
                        for (var i = 0; i < len; i++) dests[i].emit('unpipe', this, {
                            hasUnpiped: false
                        });
                        return this;
                    }

                    // try to find the right one.
                    var index = indexOf(state.pipes, dest);
                    if (index === -1) return this;
                    state.pipes.splice(index, 1);
                    state.pipesCount -= 1;
                    if (state.pipesCount === 1) state.pipes = state.pipes[0];
                    dest.emit('unpipe', this, unpipeInfo);
                    return this;
                };

                // set up data events if they are asked for
                // Ensure readable listeners eventually get something
                Readable.prototype.on = function(ev, fn) {
                    const res = Stream.prototype.on.call(this, ev, fn);
                    const state = this._readableState;
                    if (ev === 'data') {
                        // update readableListening so that resume() may be a no-op
                        // a few lines down. This is needed to support once('readable').
                        state.readableListening = this.listenerCount('readable') > 0;

                        // Try start flowing on next tick if stream isn't explicitly paused
                        if (state.flowing !== false) this.resume();
                    } else if (ev === 'readable') {
                        if (!state.endEmitted && !state.readableListening) {
                            state.readableListening = state.needReadable = true;
                            state.flowing = false;
                            state.emittedReadable = false;
                            debug('on readable', state.length, state.reading);
                            if (state.length) {
                                emitReadable(this);
                            } else if (!state.reading) {
                                process.nextTick(nReadingNextTick, this);
                            }
                        }
                    }
                    return res;
                };
                Readable.prototype.addListener = Readable.prototype.on;
                Readable.prototype.removeListener = function(ev, fn) {
                    const res = Stream.prototype.removeListener.call(this, ev, fn);
                    if (ev === 'readable') {
                        // We need to check if there is someone still listening to
                        // readable and reset the state. However this needs to happen
                        // after readable has been emitted but before I/O (nextTick) to
                        // support once('readable', fn) cycles. This means that calling
                        // resume within the same tick will have no
                        // effect.
                        process.nextTick(updateReadableListening, this);
                    }
                    return res;
                };
                Readable.prototype.removeAllListeners = function(ev) {
                    const res = Stream.prototype.removeAllListeners.apply(this, arguments);
                    if (ev === 'readable' || ev === undefined) {
                        // We need to check if there is someone still listening to
                        // readable and reset the state. However this needs to happen
                        // after readable has been emitted but before I/O (nextTick) to
                        // support once('readable', fn) cycles. This means that calling
                        // resume within the same tick will have no
                        // effect.
                        process.nextTick(updateReadableListening, this);
                    }
                    return res;
                };

                function updateReadableListening(self) {
                    const state = self._readableState;
                    state.readableListening = self.listenerCount('readable') > 0;
                    if (state.resumeScheduled && !state.paused) {
                        // flowing needs to be set to true now, otherwise
                        // the upcoming resume will not flow.
                        state.flowing = true;

                        // crude way to check if we should resume
                    } else if (self.listenerCount('data') > 0) {
                        self.resume();
                    }
                }

                function nReadingNextTick(self) {
                    debug('readable nexttick read 0');
                    self.read(0);
                }

                // pause() and resume() are remnants of the legacy readable stream API
                // If the user uses them, then switch into old mode.
                Readable.prototype.resume = function() {
                    var state = this._readableState;
                    if (!state.flowing) {
                        debug('resume');
                        // we flow only if there is no one listening
                        // for readable, but we still have to call
                        // resume()
                        state.flowing = !state.readableListening;
                        resume(this, state);
                    }
                    state.paused = false;
                    return this;
                };

                function resume(stream, state) {
                    if (!state.resumeScheduled) {
                        state.resumeScheduled = true;
                        process.nextTick(resume_, stream, state);
                    }
                }

                function resume_(stream, state) {
                    debug('resume', state.reading);
                    if (!state.reading) {
                        stream.read(0);
                    }
                    state.resumeScheduled = false;
                    stream.emit('resume');
                    flow(stream);
                    if (state.flowing && !state.reading) stream.read(0);
                }
                Readable.prototype.pause = function() {
                    debug('call pause flowing=%j', this._readableState.flowing);
                    if (this._readableState.flowing !== false) {
                        debug('pause');
                        this._readableState.flowing = false;
                        this.emit('pause');
                    }
                    this._readableState.paused = true;
                    return this;
                };

                function flow(stream) {
                    const state = stream._readableState;
                    debug('flow', state.flowing);
                    while (state.flowing && stream.read() !== null);
                }

                // wrap an old-style stream as the async data source.
                // This is *not* part of the readable stream interface.
                // It is an ugly unfortunate mess of history.
                Readable.prototype.wrap = function(stream) {
                    var state = this._readableState;
                    var paused = false;
                    stream.on('end', () => {
                        debug('wrapped end');
                        if (state.decoder && !state.ended) {
                            var chunk = state.decoder.end();
                            if (chunk && chunk.length) this.push(chunk);
                        }
                        this.push(null);
                    });
                    stream.on('data', chunk => {
                        debug('wrapped data');
                        if (state.decoder) chunk = state.decoder.write(chunk);

                        // don't skip over falsy values in objectMode
                        if (state.objectMode && (chunk === null || chunk === undefined)) return;
                        else if (!state.objectMode && (!chunk || !chunk.length)) return;
                        var ret = this.push(chunk);
                        if (!ret) {
                            paused = true;
                            stream.pause();
                        }
                    });

                    // proxy all the other methods.
                    // important when wrapping filters and duplexes.
                    for (var i in stream) {
                        if (this[i] === undefined && typeof stream[i] === 'function') {
                            this[i] = function methodWrap(method) {
                                return function methodWrapReturnFunction() {
                                    return stream[method].apply(stream, arguments);
                                };
                            }(i);
                        }
                    }

                    // proxy certain important events.
                    for (var n = 0; n < kProxyEvents.length; n++) {
                        stream.on(kProxyEvents[n], this.emit.bind(this, kProxyEvents[n]));
                    }

                    // when we try to consume some more bytes, simply unpause the
                    // underlying stream.
                    this._read = n => {
                        debug('wrapped _read', n);
                        if (paused) {
                            paused = false;
                            stream.resume();
                        }
                    };
                    return this;
                };
                if (typeof Symbol === 'function') {
                    Readable.prototype[Symbol.asyncIterator] = function() {
                        if (createReadableStreamAsyncIterator === undefined) {
                            createReadableStreamAsyncIterator = require('./internal/streams/async_iterator');
                        }
                        return createReadableStreamAsyncIterator(this);
                    };
                }
                Object.defineProperty(Readable.prototype, 'readableHighWaterMark', {
                    // making it explicit this property is not enumerable
                    // because otherwise some prototype manipulation in
                    // userland will fail
                    enumerable: false,
                    get: function get() {
                        return this._readableState.highWaterMark;
                    }
                });
                Object.defineProperty(Readable.prototype, 'readableBuffer', {
                    // making it explicit this property is not enumerable
                    // because otherwise some prototype manipulation in
                    // userland will fail
                    enumerable: false,
                    get: function get() {
                        return this._readableState && this._readableState.buffer;
                    }
                });
                Object.defineProperty(Readable.prototype, 'readableFlowing', {
                    // making it explicit this property is not enumerable
                    // because otherwise some prototype manipulation in
                    // userland will fail
                    enumerable: false,
                    get: function get() {
                        return this._readableState.flowing;
                    },
                    set: function set(state) {
                        if (this._readableState) {
                            this._readableState.flowing = state;
                        }
                    }
                });

                // exposed for testing purposes only.
                Readable._fromList = fromList;
                Object.defineProperty(Readable.prototype, 'readableLength', {
                    // making it explicit this property is not enumerable
                    // because otherwise some prototype manipulation in
                    // userland will fail
                    enumerable: false,
                    get() {
                        return this._readableState.length;
                    }
                });

                // Pluck off n bytes from an array of buffers.
                // Length is the combined lengths of all the buffers in the list.
                // This function is designed to be inlinable, so please take care when making
                // changes to the function body.
                function fromList(n, state) {
                    // nothing buffered
                    if (state.length === 0) return null;
                    var ret;
                    if (state.objectMode) ret = state.buffer.shift();
                    else if (!n || n >= state.length) {
                        // read it all, truncate the list
                        if (state.decoder) ret = state.buffer.join('');
                        else if (state.buffer.length === 1) ret = state.buffer.first();
                        else ret = state.buffer.concat(state.length);
                        state.buffer.clear();
                    } else {
                        // read part of list
                        ret = state.buffer.consume(n, state.decoder);
                    }
                    return ret;
                }

                function endReadable(stream) {
                    var state = stream._readableState;
                    debug('endReadable', state.endEmitted);
                    if (!state.endEmitted) {
                        state.ended = true;
                        process.nextTick(endReadableNT, state, stream);
                    }
                }

                function endReadableNT(state, stream) {
                    debug('endReadableNT', state.endEmitted, state.length);

                    // Check that we didn't get one last unshift.
                    if (!state.endEmitted && state.length === 0) {
                        state.endEmitted = true;
                        stream.readable = false;
                        stream.emit('end');
                        if (state.autoDestroy) {
                            // In case of duplex streams we need a way to detect
                            // if the writable side is ready for autoDestroy as well
                            const wState = stream._writableState;
                            if (!wState || wState.autoDestroy && wState.finished) {
                                stream.destroy();
                            }
                        }
                    }
                }
                if (typeof Symbol === 'function') {
                    Readable.from = function(iterable, opts) {
                        if (from === undefined) {
                            from = require('./internal/streams/from');
                        }
                        return from(Readable, iterable, opts);
                    };
                }

                function indexOf(xs, x) {
                    for (var i = 0, l = xs.length; i < l; i++) {
                        if (xs[i] === x) return i;
                    }
                    return -1;
                }
            }).call(this)
        }).call(this, require('_process'), typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
    }, {
        "../errors": 16,
        "./_stream_duplex": 17,
        "./internal/streams/async_iterator": 22,
        "./internal/streams/buffer_list": 23,
        "./internal/streams/destroy": 24,
        "./internal/streams/from": 26,
        "./internal/streams/state": 28,
        "./internal/streams/stream": 29,
        "_process": 9,
        "buffer": 3,
        "events": 5,
        "inherits": 8,
        "string_decoder/": 49,
        "util": 2
    }],
    20: [function(require, module, exports) {
        // Copyright Joyent, Inc. and other Node contributors.
        //
        // Permission is hereby granted, free of charge, to any person obtaining a
        // copy of this software and associated documentation files (the
        // "Software"), to deal in the Software without restriction, including
        // without limitation the rights to use, copy, modify, merge, publish,
        // distribute, sublicense, and/or sell copies of the Software, and to permit
        // persons to whom the Software is furnished to do so, subject to the
        // following conditions:
        //
        // The above copyright notice and this permission notice shall be included
        // in all copies or substantial portions of the Software.
        //
        // THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
        // OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
        // MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
        // NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
        // DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
        // OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
        // USE OR OTHER DEALINGS IN THE SOFTWARE.

        // a transform stream is a readable/writable stream where you do
        // something with the data.  Sometimes it's called a "filter",
        // but that's not a great name for it, since that implies a thing where
        // some bits pass through, and others are simply ignored.  (That would
        // be a valid example of a transform, of course.)
        //
        // While the output is causally related to the input, it's not a
        // necessarily symmetric or synchronous transformation.  For example,
        // a zlib stream might take multiple plain-text writes(), and then
        // emit a single compressed chunk some time in the future.
        //
        // Here's how this works:
        //
        // The Transform stream has all the aspects of the readable and writable
        // stream classes.  When you write(chunk), that calls _write(chunk,cb)
        // internally, and returns false if there's a lot of pending writes
        // buffered up.  When you call read(), that calls _read(n) until
        // there's enough pending readable data buffered up.
        //
        // In a transform stream, the written data is placed in a buffer.  When
        // _read(n) is called, it transforms the queued up data, calling the
        // buffered _write cb's as it consumes chunks.  If consuming a single
        // written chunk would result in multiple output chunks, then the first
        // outputted bit calls the readcb, and subsequent chunks just go into
        // the read buffer, and will cause it to emit 'readable' if necessary.
        //
        // This way, back-pressure is actually determined by the reading side,
        // since _read has to be called to start processing a new chunk.  However,
        // a pathological inflate type of transform can cause excessive buffering
        // here.  For example, imagine a stream where every byte of input is
        // interpreted as an integer from 0-255, and then results in that many
        // bytes of output.  Writing the 4 bytes {ff,ff,ff,ff} would result in
        // 1kb of data being output.  In this case, you could write a very small
        // amount of input, and end up with a very large amount of output.  In
        // such a pathological inflating mechanism, there'd be no way to tell
        // the system to stop doing the transform.  A single 4MB write could
        // cause the system to run out of memory.
        //
        // However, even in such a pathological case, only a single written chunk
        // would be consumed, and then the rest would wait (un-transformed) until
        // the results of the previous transformed chunk were consumed.

        'use strict';

        module.exports = Transform;
        const _require$codes = require('../errors').codes,
            ERR_METHOD_NOT_IMPLEMENTED = _require$codes.ERR_METHOD_NOT_IMPLEMENTED,
            ERR_MULTIPLE_CALLBACK = _require$codes.ERR_MULTIPLE_CALLBACK,
            ERR_TRANSFORM_ALREADY_TRANSFORMING = _require$codes.ERR_TRANSFORM_ALREADY_TRANSFORMING,
            ERR_TRANSFORM_WITH_LENGTH_0 = _require$codes.ERR_TRANSFORM_WITH_LENGTH_0;
        const Duplex = require('./_stream_duplex');
        require('inherits')(Transform, Duplex);

        function afterTransform(er, data) {
            var ts = this._transformState;
            ts.transforming = false;
            var cb = ts.writecb;
            if (cb === null) {
                return this.emit('error', new ERR_MULTIPLE_CALLBACK());
            }
            ts.writechunk = null;
            ts.writecb = null;
            if (data != null)
                // single equals check for both `null` and `undefined`
                this.push(data);
            cb(er);
            var rs = this._readableState;
            rs.reading = false;
            if (rs.needReadable || rs.length < rs.highWaterMark) {
                this._read(rs.highWaterMark);
            }
        }

        function Transform(options) {
            if (!(this instanceof Transform)) return new Transform(options);
            Duplex.call(this, options);
            this._transformState = {
                afterTransform: afterTransform.bind(this),
                needTransform: false,
                transforming: false,
                writecb: null,
                writechunk: null,
                writeencoding: null
            };

            // start out asking for a readable event once data is transformed.
            this._readableState.needReadable = true;

            // we have implemented the _read method, and done the other things
            // that Readable wants before the first _read call, so unset the
            // sync guard flag.
            this._readableState.sync = false;
            if (options) {
                if (typeof options.transform === 'function') this._transform = options.transform;
                if (typeof options.flush === 'function') this._flush = options.flush;
            }

            // When the writable side finishes, then flush out anything remaining.
            this.on('prefinish', prefinish);
        }

        function prefinish() {
            if (typeof this._flush === 'function' && !this._readableState.destroyed) {
                this._flush((er, data) => {
                    done(this, er, data);
                });
            } else {
                done(this, null, null);
            }
        }
        Transform.prototype.push = function(chunk, encoding) {
            this._transformState.needTransform = false;
            return Duplex.prototype.push.call(this, chunk, encoding);
        };

        // This is the part where you do stuff!
        // override this function in implementation classes.
        // 'chunk' is an input chunk.
        //
        // Call `push(newChunk)` to pass along transformed output
        // to the readable side.  You may call 'push' zero or more times.
        //
        // Call `cb(err)` when you are done with this chunk.  If you pass
        // an error, then that'll put the hurt on the whole operation.  If you
        // never call cb(), then you'll never get another chunk.
        Transform.prototype._transform = function(chunk, encoding, cb) {
            cb(new ERR_METHOD_NOT_IMPLEMENTED('_transform()'));
        };
        Transform.prototype._write = function(chunk, encoding, cb) {
            var ts = this._transformState;
            ts.writecb = cb;
            ts.writechunk = chunk;
            ts.writeencoding = encoding;
            if (!ts.transforming) {
                var rs = this._readableState;
                if (ts.needTransform || rs.needReadable || rs.length < rs.highWaterMark) this._read(rs.highWaterMark);
            }
        };

        // Doesn't matter what the args are here.
        // _transform does all the work.
        // That we got here means that the readable side wants more data.
        Transform.prototype._read = function(n) {
            var ts = this._transformState;
            if (ts.writechunk !== null && !ts.transforming) {
                ts.transforming = true;
                this._transform(ts.writechunk, ts.writeencoding, ts.afterTransform);
            } else {
                // mark that we need a transform, so that any data that comes in
                // will get processed, now that we've asked for it.
                ts.needTransform = true;
            }
        };
        Transform.prototype._destroy = function(err, cb) {
            Duplex.prototype._destroy.call(this, err, err2 => {
                cb(err2);
            });
        };

        function done(stream, er, data) {
            if (er) return stream.emit('error', er);
            if (data != null)
                // single equals check for both `null` and `undefined`
                stream.push(data);

            // TODO(BridgeAR): Write a test for these two error cases
            // if there's nothing in the write buffer, then that means
            // that nothing more will ever be provided
            if (stream._writableState.length) throw new ERR_TRANSFORM_WITH_LENGTH_0();
            if (stream._transformState.transforming) throw new ERR_TRANSFORM_ALREADY_TRANSFORMING();
            return stream.push(null);
        }
    }, {
        "../errors": 16,
        "./_stream_duplex": 17,
        "inherits": 8
    }],
    21: [function(require, module, exports) {
        (function(process, global) {
            (function() {
                // Copyright Joyent, Inc. and other Node contributors.
                //
                // Permission is hereby granted, free of charge, to any person obtaining a
                // copy of this software and associated documentation files (the
                // "Software"), to deal in the Software without restriction, including
                // without limitation the rights to use, copy, modify, merge, publish,
                // distribute, sublicense, and/or sell copies of the Software, and to permit
                // persons to whom the Software is furnished to do so, subject to the
                // following conditions:
                //
                // The above copyright notice and this permission notice shall be included
                // in all copies or substantial portions of the Software.
                //
                // THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
                // OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
                // MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
                // NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
                // DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
                // OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
                // USE OR OTHER DEALINGS IN THE SOFTWARE.

                // A bit simpler than readable streams.
                // Implement an async ._write(chunk, encoding, cb), and it'll handle all
                // the drain event emission and buffering.

                'use strict';

                module.exports = Writable;

                /* <replacement> */
                function WriteReq(chunk, encoding, cb) {
                    this.chunk = chunk;
                    this.encoding = encoding;
                    this.callback = cb;
                    this.next = null;
                }

                // It seems a linked list but it is not
                // there will be only 2 of these for each stream
                function CorkedRequest(state) {
                    this.next = null;
                    this.entry = null;
                    this.finish = () => {
                        onCorkedFinish(this, state);
                    };
                }
                /* </replacement> */

                /*<replacement>*/
                var Duplex;
                /*</replacement>*/

                Writable.WritableState = WritableState;

                /*<replacement>*/
                const internalUtil = {
                    deprecate: require('util-deprecate')
                };
                /*</replacement>*/

                /*<replacement>*/
                var Stream = require('./internal/streams/stream');
                /*</replacement>*/

                const Buffer = require('buffer').Buffer;
                const OurUint8Array = (typeof global !== 'undefined' ? global : typeof window !== 'undefined' ? window : typeof self !== 'undefined' ? self : {}).Uint8Array || function() {};

                function _uint8ArrayToBuffer(chunk) {
                    return Buffer.from(chunk);
                }

                function _isUint8Array(obj) {
                    return Buffer.isBuffer(obj) || obj instanceof OurUint8Array;
                }
                const destroyImpl = require('./internal/streams/destroy');
                const _require = require('./internal/streams/state'),
                    getHighWaterMark = _require.getHighWaterMark;
                const _require$codes = require('../errors').codes,
                    ERR_INVALID_ARG_TYPE = _require$codes.ERR_INVALID_ARG_TYPE,
                    ERR_METHOD_NOT_IMPLEMENTED = _require$codes.ERR_METHOD_NOT_IMPLEMENTED,
                    ERR_MULTIPLE_CALLBACK = _require$codes.ERR_MULTIPLE_CALLBACK,
                    ERR_STREAM_CANNOT_PIPE = _require$codes.ERR_STREAM_CANNOT_PIPE,
                    ERR_STREAM_DESTROYED = _require$codes.ERR_STREAM_DESTROYED,
                    ERR_STREAM_NULL_VALUES = _require$codes.ERR_STREAM_NULL_VALUES,
                    ERR_STREAM_WRITE_AFTER_END = _require$codes.ERR_STREAM_WRITE_AFTER_END,
                    ERR_UNKNOWN_ENCODING = _require$codes.ERR_UNKNOWN_ENCODING;
                const errorOrDestroy = destroyImpl.errorOrDestroy;
                require('inherits')(Writable, Stream);

                function nop() {}

                function WritableState(options, stream, isDuplex) {
                    Duplex = Duplex || require('./_stream_duplex');
                    options = options || {};

                    // Duplex streams are both readable and writable, but share
                    // the same options object.
                    // However, some cases require setting options to different
                    // values for the readable and the writable sides of the duplex stream,
                    // e.g. options.readableObjectMode vs. options.writableObjectMode, etc.
                    if (typeof isDuplex !== 'boolean') isDuplex = stream instanceof Duplex;

                    // object stream flag to indicate whether or not this stream
                    // contains buffers or objects.
                    this.objectMode = !!options.objectMode;
                    if (isDuplex) this.objectMode = this.objectMode || !!options.writableObjectMode;

                    // the point at which write() starts returning false
                    // Note: 0 is a valid value, means that we always return false if
                    // the entire buffer is not flushed immediately on write()
                    this.highWaterMark = getHighWaterMark(this, options, 'writableHighWaterMark', isDuplex);

                    // if _final has been called
                    this.finalCalled = false;

                    // drain event flag.
                    this.needDrain = false;
                    // at the start of calling end()
                    this.ending = false;
                    // when end() has been called, and returned
                    this.ended = false;
                    // when 'finish' is emitted
                    this.finished = false;

                    // has it been destroyed
                    this.destroyed = false;

                    // should we decode strings into buffers before passing to _write?
                    // this is here so that some node-core streams can optimize string
                    // handling at a lower level.
                    var noDecode = options.decodeStrings === false;
                    this.decodeStrings = !noDecode;

                    // Crypto is kind of old and crusty.  Historically, its default string
                    // encoding is 'binary' so we have to make this configurable.
                    // Everything else in the universe uses 'utf8', though.
                    this.defaultEncoding = options.defaultEncoding || 'utf8';

                    // not an actual buffer we keep track of, but a measurement
                    // of how much we're waiting to get pushed to some underlying
                    // socket or file.
                    this.length = 0;

                    // a flag to see when we're in the middle of a write.
                    this.writing = false;

                    // when true all writes will be buffered until .uncork() call
                    this.corked = 0;

                    // a flag to be able to tell if the onwrite cb is called immediately,
                    // or on a later tick.  We set this to true at first, because any
                    // actions that shouldn't happen until "later" should generally also
                    // not happen before the first write call.
                    this.sync = true;

                    // a flag to know if we're processing previously buffered items, which
                    // may call the _write() callback in the same tick, so that we don't
                    // end up in an overlapped onwrite situation.
                    this.bufferProcessing = false;

                    // the callback that's passed to _write(chunk,cb)
                    this.onwrite = function(er) {
                        onwrite(stream, er);
                    };

                    // the callback that the user supplies to write(chunk,encoding,cb)
                    this.writecb = null;

                    // the amount that is being written when _write is called.
                    this.writelen = 0;
                    this.bufferedRequest = null;
                    this.lastBufferedRequest = null;

                    // number of pending user-supplied write callbacks
                    // this must be 0 before 'finish' can be emitted
                    this.pendingcb = 0;

                    // emit prefinish if the only thing we're waiting for is _write cbs
                    // This is relevant for synchronous Transform streams
                    this.prefinished = false;

                    // True if the error was already emitted and should not be thrown again
                    this.errorEmitted = false;

                    // Should close be emitted on destroy. Defaults to true.
                    this.emitClose = options.emitClose !== false;

                    // Should .destroy() be called after 'finish' (and potentially 'end')
                    this.autoDestroy = !!options.autoDestroy;

                    // count buffered requests
                    this.bufferedRequestCount = 0;

                    // allocate the first CorkedRequest, there is always
                    // one allocated and free to use, and we maintain at most two
                    this.corkedRequestsFree = new CorkedRequest(this);
                }
                WritableState.prototype.getBuffer = function getBuffer() {
                    var current = this.bufferedRequest;
                    var out = [];
                    while (current) {
                        out.push(current);
                        current = current.next;
                    }
                    return out;
                };
                (function() {
                    try {
                        Object.defineProperty(WritableState.prototype, 'buffer', {
                            get: internalUtil.deprecate(function writableStateBufferGetter() {
                                return this.getBuffer();
                            }, '_writableState.buffer is deprecated. Use _writableState.getBuffer ' + 'instead.', 'DEP0003')
                        });
                    } catch (_) {}
                })();

                // Test _writableState for inheritance to account for Duplex streams,
                // whose prototype chain only points to Readable.
                var realHasInstance;
                if (typeof Symbol === 'function' && Symbol.hasInstance && typeof Function.prototype[Symbol.hasInstance] === 'function') {
                    realHasInstance = Function.prototype[Symbol.hasInstance];
                    Object.defineProperty(Writable, Symbol.hasInstance, {
                        value: function value(object) {
                            if (realHasInstance.call(this, object)) return true;
                            if (this !== Writable) return false;
                            return object && object._writableState instanceof WritableState;
                        }
                    });
                } else {
                    realHasInstance = function realHasInstance(object) {
                        return object instanceof this;
                    };
                }

                function Writable(options) {
                    Duplex = Duplex || require('./_stream_duplex');

                    // Writable ctor is applied to Duplexes, too.
                    // `realHasInstance` is necessary because using plain `instanceof`
                    // would return false, as no `_writableState` property is attached.

                    // Trying to use the custom `instanceof` for Writable here will also break the
                    // Node.js LazyTransform implementation, which has a non-trivial getter for
                    // `_writableState` that would lead to infinite recursion.

                    // Checking for a Stream.Duplex instance is faster here instead of inside
                    // the WritableState constructor, at least with V8 6.5
                    const isDuplex = this instanceof Duplex;
                    if (!isDuplex && !realHasInstance.call(Writable, this)) return new Writable(options);
                    this._writableState = new WritableState(options, this, isDuplex);

                    // legacy.
                    this.writable = true;
                    if (options) {
                        if (typeof options.write === 'function') this._write = options.write;
                        if (typeof options.writev === 'function') this._writev = options.writev;
                        if (typeof options.destroy === 'function') this._destroy = options.destroy;
                        if (typeof options.final === 'function') this._final = options.final;
                    }
                    Stream.call(this);
                }

                // Otherwise people can pipe Writable streams, which is just wrong.
                Writable.prototype.pipe = function() {
                    errorOrDestroy(this, new ERR_STREAM_CANNOT_PIPE());
                };

                function writeAfterEnd(stream, cb) {
                    var er = new ERR_STREAM_WRITE_AFTER_END();
                    // TODO: defer error events consistently everywhere, not just the cb
                    errorOrDestroy(stream, er);
                    process.nextTick(cb, er);
                }

                // Checks that a user-supplied chunk is valid, especially for the particular
                // mode the stream is in. Currently this means that `null` is never accepted
                // and undefined/non-string values are only allowed in object mode.
                function validChunk(stream, state, chunk, cb) {
                    var er;
                    if (chunk === null) {
                        er = new ERR_STREAM_NULL_VALUES();
                    } else if (typeof chunk !== 'string' && !state.objectMode) {
                        er = new ERR_INVALID_ARG_TYPE('chunk', ['string', 'Buffer'], chunk);
                    }
                    if (er) {
                        errorOrDestroy(stream, er);
                        process.nextTick(cb, er);
                        return false;
                    }
                    return true;
                }
                Writable.prototype.write = function(chunk, encoding, cb) {
                    var state = this._writableState;
                    var ret = false;
                    var isBuf = !state.objectMode && _isUint8Array(chunk);
                    if (isBuf && !Buffer.isBuffer(chunk)) {
                        chunk = _uint8ArrayToBuffer(chunk);
                    }
                    if (typeof encoding === 'function') {
                        cb = encoding;
                        encoding = null;
                    }
                    if (isBuf) encoding = 'buffer';
                    else if (!encoding) encoding = state.defaultEncoding;
                    if (typeof cb !== 'function') cb = nop;
                    if (state.ending) writeAfterEnd(this, cb);
                    else if (isBuf || validChunk(this, state, chunk, cb)) {
                        state.pendingcb++;
                        ret = writeOrBuffer(this, state, isBuf, chunk, encoding, cb);
                    }
                    return ret;
                };
                Writable.prototype.cork = function() {
                    this._writableState.corked++;
                };
                Writable.prototype.uncork = function() {
                    var state = this._writableState;
                    if (state.corked) {
                        state.corked--;
                        if (!state.writing && !state.corked && !state.bufferProcessing && state.bufferedRequest) clearBuffer(this, state);
                    }
                };
                Writable.prototype.setDefaultEncoding = function setDefaultEncoding(encoding) {
                    // node::ParseEncoding() requires lower case.
                    if (typeof encoding === 'string') encoding = encoding.toLowerCase();
                    if (!(['hex', 'utf8', 'utf-8', 'ascii', 'binary', 'base64', 'ucs2', 'ucs-2', 'utf16le', 'utf-16le', 'raw'].indexOf((encoding + '').toLowerCase()) > -1)) throw new ERR_UNKNOWN_ENCODING(encoding);
                    this._writableState.defaultEncoding = encoding;
                    return this;
                };
                Object.defineProperty(Writable.prototype, 'writableBuffer', {
                    // making it explicit this property is not enumerable
                    // because otherwise some prototype manipulation in
                    // userland will fail
                    enumerable: false,
                    get: function get() {
                        return this._writableState && this._writableState.getBuffer();
                    }
                });

                function decodeChunk(state, chunk, encoding) {
                    if (!state.objectMode && state.decodeStrings !== false && typeof chunk === 'string') {
                        chunk = Buffer.from(chunk, encoding);
                    }
                    return chunk;
                }
                Object.defineProperty(Writable.prototype, 'writableHighWaterMark', {
                    // making it explicit this property is not enumerable
                    // because otherwise some prototype manipulation in
                    // userland will fail
                    enumerable: false,
                    get: function get() {
                        return this._writableState.highWaterMark;
                    }
                });

                // if we're already writing something, then just put this
                // in the queue, and wait our turn.  Otherwise, call _write
                // If we return false, then we need a drain event, so set that flag.
                function writeOrBuffer(stream, state, isBuf, chunk, encoding, cb) {
                    if (!isBuf) {
                        var newChunk = decodeChunk(state, chunk, encoding);
                        if (chunk !== newChunk) {
                            isBuf = true;
                            encoding = 'buffer';
                            chunk = newChunk;
                        }
                    }
                    var len = state.objectMode ? 1 : chunk.length;
                    state.length += len;
                    var ret = state.length < state.highWaterMark;
                    // we must ensure that previous needDrain will not be reset to false.
                    if (!ret) state.needDrain = true;
                    if (state.writing || state.corked) {
                        var last = state.lastBufferedRequest;
                        state.lastBufferedRequest = {
                            chunk,
                            encoding,
                            isBuf,
                            callback: cb,
                            next: null
                        };
                        if (last) {
                            last.next = state.lastBufferedRequest;
                        } else {
                            state.bufferedRequest = state.lastBufferedRequest;
                        }
                        state.bufferedRequestCount += 1;
                    } else {
                        doWrite(stream, state, false, len, chunk, encoding, cb);
                    }
                    return ret;
                }

                function doWrite(stream, state, writev, len, chunk, encoding, cb) {
                    state.writelen = len;
                    state.writecb = cb;
                    state.writing = true;
                    state.sync = true;
                    if (state.destroyed) state.onwrite(new ERR_STREAM_DESTROYED('write'));
                    else if (writev) stream._writev(chunk, state.onwrite);
                    else stream._write(chunk, encoding, state.onwrite);
                    state.sync = false;
                }

                function onwriteError(stream, state, sync, er, cb) {
                    --state.pendingcb;
                    if (sync) {
                        // defer the callback if we are being called synchronously
                        // to avoid piling up things on the stack
                        process.nextTick(cb, er);
                        // this can emit finish, and it will always happen
                        // after error
                        process.nextTick(finishMaybe, stream, state);
                        stream._writableState.errorEmitted = true;
                        errorOrDestroy(stream, er);
                    } else {
                        // the caller expect this to happen before if
                        // it is async
                        cb(er);
                        stream._writableState.errorEmitted = true;
                        errorOrDestroy(stream, er);
                        // this can emit finish, but finish must
                        // always follow error
                        finishMaybe(stream, state);
                    }
                }

                function onwriteStateUpdate(state) {
                    state.writing = false;
                    state.writecb = null;
                    state.length -= state.writelen;
                    state.writelen = 0;
                }

                function onwrite(stream, er) {
                    var state = stream._writableState;
                    var sync = state.sync;
                    var cb = state.writecb;
                    if (typeof cb !== 'function') throw new ERR_MULTIPLE_CALLBACK();
                    onwriteStateUpdate(state);
                    if (er) onwriteError(stream, state, sync, er, cb);
                    else {
                        // Check if we're actually ready to finish, but don't emit yet
                        var finished = needFinish(state) || stream.destroyed;
                        if (!finished && !state.corked && !state.bufferProcessing && state.bufferedRequest) {
                            clearBuffer(stream, state);
                        }
                        if (sync) {
                            process.nextTick(afterWrite, stream, state, finished, cb);
                        } else {
                            afterWrite(stream, state, finished, cb);
                        }
                    }
                }

                function afterWrite(stream, state, finished, cb) {
                    if (!finished) onwriteDrain(stream, state);
                    state.pendingcb--;
                    cb();
                    finishMaybe(stream, state);
                }

                // Must force callback to be called on nextTick, so that we don't
                // emit 'drain' before the write() consumer gets the 'false' return
                // value, and has a chance to attach a 'drain' listener.
                function onwriteDrain(stream, state) {
                    if (state.length === 0 && state.needDrain) {
                        state.needDrain = false;
                        stream.emit('drain');
                    }
                }

                // if there's something in the buffer waiting, then process it
                function clearBuffer(stream, state) {
                    state.bufferProcessing = true;
                    var entry = state.bufferedRequest;
                    if (stream._writev && entry && entry.next) {
                        // Fast case, write everything using _writev()
                        var l = state.bufferedRequestCount;
                        var buffer = new Array(l);
                        var holder = state.corkedRequestsFree;
                        holder.entry = entry;
                        var count = 0;
                        var allBuffers = true;
                        while (entry) {
                            buffer[count] = entry;
                            if (!entry.isBuf) allBuffers = false;
                            entry = entry.next;
                            count += 1;
                        }
                        buffer.allBuffers = allBuffers;
                        doWrite(stream, state, true, state.length, buffer, '', holder.finish);

                        // doWrite is almost always async, defer these to save a bit of time
                        // as the hot path ends with doWrite
                        state.pendingcb++;
                        state.lastBufferedRequest = null;
                        if (holder.next) {
                            state.corkedRequestsFree = holder.next;
                            holder.next = null;
                        } else {
                            state.corkedRequestsFree = new CorkedRequest(state);
                        }
                        state.bufferedRequestCount = 0;
                    } else {
                        // Slow case, write chunks one-by-one
                        while (entry) {
                            var chunk = entry.chunk;
                            var encoding = entry.encoding;
                            var cb = entry.callback;
                            var len = state.objectMode ? 1 : chunk.length;
                            doWrite(stream, state, false, len, chunk, encoding, cb);
                            entry = entry.next;
                            state.bufferedRequestCount--;
                            // if we didn't call the onwrite immediately, then
                            // it means that we need to wait until it does.
                            // also, that means that the chunk and cb are currently
                            // being processed, so move the buffer counter past them.
                            if (state.writing) {
                                break;
                            }
                        }
                        if (entry === null) state.lastBufferedRequest = null;
                    }
                    state.bufferedRequest = entry;
                    state.bufferProcessing = false;
                }
                Writable.prototype._write = function(chunk, encoding, cb) {
                    cb(new ERR_METHOD_NOT_IMPLEMENTED('_write()'));
                };
                Writable.prototype._writev = null;
                Writable.prototype.end = function(chunk, encoding, cb) {
                    var state = this._writableState;
                    if (typeof chunk === 'function') {
                        cb = chunk;
                        chunk = null;
                        encoding = null;
                    } else if (typeof encoding === 'function') {
                        cb = encoding;
                        encoding = null;
                    }
                    if (chunk !== null && chunk !== undefined) this.write(chunk, encoding);

                    // .end() fully uncorks
                    if (state.corked) {
                        state.corked = 1;
                        this.uncork();
                    }

                    // ignore unnecessary end() calls.
                    if (!state.ending) endWritable(this, state, cb);
                    return this;
                };
                Object.defineProperty(Writable.prototype, 'writableLength', {
                    // making it explicit this property is not enumerable
                    // because otherwise some prototype manipulation in
                    // userland will fail
                    enumerable: false,
                    get() {
                        return this._writableState.length;
                    }
                });

                function needFinish(state) {
                    return state.ending && state.length === 0 && state.bufferedRequest === null && !state.finished && !state.writing;
                }

                function callFinal(stream, state) {
                    stream._final(err => {
                        state.pendingcb--;
                        if (err) {
                            errorOrDestroy(stream, err);
                        }
                        state.prefinished = true;
                        stream.emit('prefinish');
                        finishMaybe(stream, state);
                    });
                }

                function prefinish(stream, state) {
                    if (!state.prefinished && !state.finalCalled) {
                        if (typeof stream._final === 'function' && !state.destroyed) {
                            state.pendingcb++;
                            state.finalCalled = true;
                            process.nextTick(callFinal, stream, state);
                        } else {
                            state.prefinished = true;
                            stream.emit('prefinish');
                        }
                    }
                }

                function finishMaybe(stream, state) {
                    var need = needFinish(state);
                    if (need) {
                        prefinish(stream, state);
                        if (state.pendingcb === 0) {
                            state.finished = true;
                            stream.emit('finish');
                            if (state.autoDestroy) {
                                // In case of duplex streams we need a way to detect
                                // if the readable side is ready for autoDestroy as well
                                const rState = stream._readableState;
                                if (!rState || rState.autoDestroy && rState.endEmitted) {
                                    stream.destroy();
                                }
                            }
                        }
                    }
                    return need;
                }

                function endWritable(stream, state, cb) {
                    state.ending = true;
                    finishMaybe(stream, state);
                    if (cb) {
                        if (state.finished) process.nextTick(cb);
                        else stream.once('finish', cb);
                    }
                    state.ended = true;
                    stream.writable = false;
                }

                function onCorkedFinish(corkReq, state, err) {
                    var entry = corkReq.entry;
                    corkReq.entry = null;
                    while (entry) {
                        var cb = entry.callback;
                        state.pendingcb--;
                        cb(err);
                        entry = entry.next;
                    }

                    // reuse the free corkReq.
                    state.corkedRequestsFree.next = corkReq;
                }
                Object.defineProperty(Writable.prototype, 'destroyed', {
                    // making it explicit this property is not enumerable
                    // because otherwise some prototype manipulation in
                    // userland will fail
                    enumerable: false,
                    get() {
                        if (this._writableState === undefined) {
                            return false;
                        }
                        return this._writableState.destroyed;
                    },
                    set(value) {
                        // we ignore the value if the stream
                        // has not been initialized yet
                        if (!this._writableState) {
                            return;
                        }

                        // backward compatibility, the user is explicitly
                        // managing destroyed
                        this._writableState.destroyed = value;
                    }
                });
                Writable.prototype.destroy = destroyImpl.destroy;
                Writable.prototype._undestroy = destroyImpl.undestroy;
                Writable.prototype._destroy = function(err, cb) {
                    cb(err);
                };
            }).call(this)
        }).call(this, require('_process'), typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
    }, {
        "../errors": 16,
        "./_stream_duplex": 17,
        "./internal/streams/destroy": 24,
        "./internal/streams/state": 28,
        "./internal/streams/stream": 29,
        "_process": 9,
        "buffer": 3,
        "inherits": 8,
        "util-deprecate": 53
    }],
    22: [function(require, module, exports) {
        (function(process) {
            (function() {
                'use strict';

                const finished = require('./end-of-stream');
                const kLastResolve = Symbol('lastResolve');
                const kLastReject = Symbol('lastReject');
                const kError = Symbol('error');
                const kEnded = Symbol('ended');
                const kLastPromise = Symbol('lastPromise');
                const kHandlePromise = Symbol('handlePromise');
                const kStream = Symbol('stream');

                function createIterResult(value, done) {
                    return {
                        value,
                        done
                    };
                }

                function readAndResolve(iter) {
                    const resolve = iter[kLastResolve];
                    if (resolve !== null) {
                        const data = iter[kStream].read();
                        // we defer if data is null
                        // we can be expecting either 'end' or
                        // 'error'
                        if (data !== null) {
                            iter[kLastPromise] = null;
                            iter[kLastResolve] = null;
                            iter[kLastReject] = null;
                            resolve(createIterResult(data, false));
                        }
                    }
                }

                function onReadable(iter) {
                    // we wait for the next tick, because it might
                    // emit an error with process.nextTick
                    process.nextTick(readAndResolve, iter);
                }

                function wrapForNext(lastPromise, iter) {
                    return (resolve, reject) => {
                        lastPromise.then(() => {
                            if (iter[kEnded]) {
                                resolve(createIterResult(undefined, true));
                                return;
                            }
                            iter[kHandlePromise](resolve, reject);
                        }, reject);
                    };
                }
                const AsyncIteratorPrototype = Object.getPrototypeOf(function() {});
                const ReadableStreamAsyncIteratorPrototype = Object.setPrototypeOf({
                    get stream() {
                        return this[kStream];
                    },
                    next() {
                        // if we have detected an error in the meanwhile
                        // reject straight away
                        const error = this[kError];
                        if (error !== null) {
                            return Promise.reject(error);
                        }
                        if (this[kEnded]) {
                            return Promise.resolve(createIterResult(undefined, true));
                        }
                        if (this[kStream].destroyed) {
                            // We need to defer via nextTick because if .destroy(err) is
                            // called, the error will be emitted via nextTick, and
                            // we cannot guarantee that there is no error lingering around
                            // waiting to be emitted.
                            return new Promise((resolve, reject) => {
                                process.nextTick(() => {
                                    if (this[kError]) {
                                        reject(this[kError]);
                                    } else {
                                        resolve(createIterResult(undefined, true));
                                    }
                                });
                            });
                        }

                        // if we have multiple next() calls
                        // we will wait for the previous Promise to finish
                        // this logic is optimized to support for await loops,
                        // where next() is only called once at a time
                        const lastPromise = this[kLastPromise];
                        let promise;
                        if (lastPromise) {
                            promise = new Promise(wrapForNext(lastPromise, this));
                        } else {
                            // fast path needed to support multiple this.push()
                            // without triggering the next() queue
                            const data = this[kStream].read();
                            if (data !== null) {
                                return Promise.resolve(createIterResult(data, false));
                            }
                            promise = new Promise(this[kHandlePromise]);
                        }
                        this[kLastPromise] = promise;
                        return promise;
                    },
                    [Symbol.asyncIterator]() {
                        return this;
                    },
                    return () {
                        // destroy(err, cb) is a private API
                        // we can guarantee we have that here, because we control the
                        // Readable class this is attached to
                        return new Promise((resolve, reject) => {
                            this[kStream].destroy(null, err => {
                                if (err) {
                                    reject(err);
                                    return;
                                }
                                resolve(createIterResult(undefined, true));
                            });
                        });
                    }
                }, AsyncIteratorPrototype);
                const createReadableStreamAsyncIterator = stream => {
                    const iterator = Object.create(ReadableStreamAsyncIteratorPrototype, {
                        [kStream]: {
                            value: stream,
                            writable: true
                        },
                        [kLastResolve]: {
                            value: null,
                            writable: true
                        },
                        [kLastReject]: {
                            value: null,
                            writable: true
                        },
                        [kError]: {
                            value: null,
                            writable: true
                        },
                        [kEnded]: {
                            value: stream._readableState.endEmitted,
                            writable: true
                        },
                        // the function passed to new Promise
                        // is cached so we avoid allocating a new
                        // closure at every run
                        [kHandlePromise]: {
                            value: (resolve, reject) => {
                                const data = iterator[kStream].read();
                                if (data) {
                                    iterator[kLastPromise] = null;
                                    iterator[kLastResolve] = null;
                                    iterator[kLastReject] = null;
                                    resolve(createIterResult(data, false));
                                } else {
                                    iterator[kLastResolve] = resolve;
                                    iterator[kLastReject] = reject;
                                }
                            },
                            writable: true
                        }
                    });
                    iterator[kLastPromise] = null;
                    finished(stream, err => {
                        if (err && err.code !== 'ERR_STREAM_PREMATURE_CLOSE') {
                            const reject = iterator[kLastReject];
                            // reject if we are waiting for data in the Promise
                            // returned by next() and store the error
                            if (reject !== null) {
                                iterator[kLastPromise] = null;
                                iterator[kLastResolve] = null;
                                iterator[kLastReject] = null;
                                reject(err);
                            }
                            iterator[kError] = err;
                            return;
                        }
                        const resolve = iterator[kLastResolve];
                        if (resolve !== null) {
                            iterator[kLastPromise] = null;
                            iterator[kLastResolve] = null;
                            iterator[kLastReject] = null;
                            resolve(createIterResult(undefined, true));
                        }
                        iterator[kEnded] = true;
                    });
                    stream.on('readable', onReadable.bind(null, iterator));
                    return iterator;
                };
                module.exports = createReadableStreamAsyncIterator;
            }).call(this)
        }).call(this, require('_process'))
    }, {
        "./end-of-stream": 25,
        "_process": 9
    }],
    23: [function(require, module, exports) {
        'use strict';

        function ownKeys(object, enumerableOnly) {
            var keys = Object.keys(object);
            if (Object.getOwnPropertySymbols) {
                var symbols = Object.getOwnPropertySymbols(object);
                enumerableOnly && (symbols = symbols.filter(function(sym) {
                    return Object.getOwnPropertyDescriptor(object, sym).enumerable;
                })), keys.push.apply(keys, symbols);
            }
            return keys;
        }

        function _objectSpread(target) {
            for (var i = 1; i < arguments.length; i++) {
                var source = null != arguments[i] ? arguments[i] : {};
                i % 2 ? ownKeys(Object(source), !0).forEach(function(key) {
                    _defineProperty(target, key, source[key]);
                }) : Object.getOwnPropertyDescriptors ? Object.defineProperties(target, Object.getOwnPropertyDescriptors(source)) : ownKeys(Object(source)).forEach(function(key) {
                    Object.defineProperty(target, key, Object.getOwnPropertyDescriptor(source, key));
                });
            }
            return target;
        }

        function _defineProperty(obj, key, value) {
            key = _toPropertyKey(key);
            if (key in obj) {
                Object.defineProperty(obj, key, {
                    value: value,
                    enumerable: true,
                    configurable: true,
                    writable: true
                });
            } else {
                obj[key] = value;
            }
            return obj;
        }

        function _toPropertyKey(arg) {
            var key = _toPrimitive(arg, "string");
            return typeof key === "symbol" ? key : String(key);
        }

        function _toPrimitive(input, hint) {
            if (typeof input !== "object" || input === null) return input;
            var prim = input[Symbol.toPrimitive];
            if (prim !== undefined) {
                var res = prim.call(input, hint || "default");
                if (typeof res !== "object") return res;
                throw new TypeError("@@toPrimitive must return a primitive value.");
            }
            return (hint === "string" ? String : Number)(input);
        }
        const _require = require('buffer'),
            Buffer = _require.Buffer;
        const _require2 = require('util'),
            inspect = _require2.inspect;
        const custom = inspect && inspect.custom || 'inspect';

        function copyBuffer(src, target, offset) {
            Buffer.prototype.copy.call(src, target, offset);
        }
        module.exports = class BufferList {
            constructor() {
                this.head = null;
                this.tail = null;
                this.length = 0;
            }
            push(v) {
                const entry = {
                    data: v,
                    next: null
                };
                if (this.length > 0) this.tail.next = entry;
                else this.head = entry;
                this.tail = entry;
                ++this.length;
            }
            unshift(v) {
                const entry = {
                    data: v,
                    next: this.head
                };
                if (this.length === 0) this.tail = entry;
                this.head = entry;
                ++this.length;
            }
            shift() {
                if (this.length === 0) return;
                const ret = this.head.data;
                if (this.length === 1) this.head = this.tail = null;
                else this.head = this.head.next;
                --this.length;
                return ret;
            }
            clear() {
                this.head = this.tail = null;
                this.length = 0;
            }
            join(s) {
                if (this.length === 0) return '';
                var p = this.head;
                var ret = '' + p.data;
                while (p = p.next) ret += s + p.data;
                return ret;
            }
            concat(n) {
                if (this.length === 0) return Buffer.alloc(0);
                const ret = Buffer.allocUnsafe(n >>> 0);
                var p = this.head;
                var i = 0;
                while (p) {
                    copyBuffer(p.data, ret, i);
                    i += p.data.length;
                    p = p.next;
                }
                return ret;
            }

            // Consumes a specified amount of bytes or characters from the buffered data.
            consume(n, hasStrings) {
                var ret;
                if (n < this.head.data.length) {
                    // `slice` is the same for buffers and strings.
                    ret = this.head.data.slice(0, n);
                    this.head.data = this.head.data.slice(n);
                } else if (n === this.head.data.length) {
                    // First chunk is a perfect match.
                    ret = this.shift();
                } else {
                    // Result spans more than one buffer.
                    ret = hasStrings ? this._getString(n) : this._getBuffer(n);
                }
                return ret;
            }
            first() {
                return this.head.data;
            }

            // Consumes a specified amount of characters from the buffered data.
            _getString(n) {
                var p = this.head;
                var c = 1;
                var ret = p.data;
                n -= ret.length;
                while (p = p.next) {
                    const str = p.data;
                    const nb = n > str.length ? str.length : n;
                    if (nb === str.length) ret += str;
                    else ret += str.slice(0, n);
                    n -= nb;
                    if (n === 0) {
                        if (nb === str.length) {
                            ++c;
                            if (p.next) this.head = p.next;
                            else this.head = this.tail = null;
                        } else {
                            this.head = p;
                            p.data = str.slice(nb);
                        }
                        break;
                    }
                    ++c;
                }
                this.length -= c;
                return ret;
            }

            // Consumes a specified amount of bytes from the buffered data.
            _getBuffer(n) {
                const ret = Buffer.allocUnsafe(n);
                var p = this.head;
                var c = 1;
                p.data.copy(ret);
                n -= p.data.length;
                while (p = p.next) {
                    const buf = p.data;
                    const nb = n > buf.length ? buf.length : n;
                    buf.copy(ret, ret.length - n, 0, nb);
                    n -= nb;
                    if (n === 0) {
                        if (nb === buf.length) {
                            ++c;
                            if (p.next) this.head = p.next;
                            else this.head = this.tail = null;
                        } else {
                            this.head = p;
                            p.data = buf.slice(nb);
                        }
                        break;
                    }
                    ++c;
                }
                this.length -= c;
                return ret;
            }

            // Make sure the linked list only shows the minimal necessary information.
            [custom](_, options) {
                return inspect(this, _objectSpread(_objectSpread({}, options), {}, {
                    // Only inspect one level.
                    depth: 0,
                    // It should not recurse.
                    customInspect: false
                }));
            }
        };
    }, {
        "buffer": 3,
        "util": 2
    }],
    24: [function(require, module, exports) {
        (function(process) {
            (function() {
                'use strict';

                // undocumented cb() API, needed for core, not for public API
                function destroy(err, cb) {
                    const readableDestroyed = this._readableState && this._readableState.destroyed;
                    const writableDestroyed = this._writableState && this._writableState.destroyed;
                    if (readableDestroyed || writableDestroyed) {
                        if (cb) {
                            cb(err);
                        } else if (err) {
                            if (!this._writableState) {
                                process.nextTick(emitErrorNT, this, err);
                            } else if (!this._writableState.errorEmitted) {
                                this._writableState.errorEmitted = true;
                                process.nextTick(emitErrorNT, this, err);
                            }
                        }
                        return this;
                    }

                    // we set destroyed to true before firing error callbacks in order
                    // to make it re-entrance safe in case destroy() is called within callbacks

                    if (this._readableState) {
                        this._readableState.destroyed = true;
                    }

                    // if this is a duplex stream mark the writable part as destroyed as well
                    if (this._writableState) {
                        this._writableState.destroyed = true;
                    }
                    this._destroy(err || null, err => {
                        if (!cb && err) {
                            if (!this._writableState) {
                                process.nextTick(emitErrorAndCloseNT, this, err);
                            } else if (!this._writableState.errorEmitted) {
                                this._writableState.errorEmitted = true;
                                process.nextTick(emitErrorAndCloseNT, this, err);
                            } else {
                                process.nextTick(emitCloseNT, this);
                            }
                        } else if (cb) {
                            process.nextTick(emitCloseNT, this);
                            cb(err);
                        } else {
                            process.nextTick(emitCloseNT, this);
                        }
                    });
                    return this;
                }

                function emitErrorAndCloseNT(self, err) {
                    emitErrorNT(self, err);
                    emitCloseNT(self);
                }

                function emitCloseNT(self) {
                    if (self._writableState && !self._writableState.emitClose) return;
                    if (self._readableState && !self._readableState.emitClose) return;
                    self.emit('close');
                }

                function undestroy() {
                    if (this._readableState) {
                        this._readableState.destroyed = false;
                        this._readableState.reading = false;
                        this._readableState.ended = false;
                        this._readableState.endEmitted = false;
                    }
                    if (this._writableState) {
                        this._writableState.destroyed = false;
                        this._writableState.ended = false;
                        this._writableState.ending = false;
                        this._writableState.finalCalled = false;
                        this._writableState.prefinished = false;
                        this._writableState.finished = false;
                        this._writableState.errorEmitted = false;
                    }
                }

                function emitErrorNT(self, err) {
                    self.emit('error', err);
                }

                function errorOrDestroy(stream, err) {
                    // We have tests that rely on errors being emitted
                    // in the same tick, so changing this is semver major.
                    // For now when you opt-in to autoDestroy we allow
                    // the error to be emitted nextTick. In a future
                    // semver major update we should change the default to this.

                    const rState = stream._readableState;
                    const wState = stream._writableState;
                    if (rState && rState.autoDestroy || wState && wState.autoDestroy) stream.destroy(err);
                    else stream.emit('error', err);
                }
                module.exports = {
                    destroy,
                    undestroy,
                    errorOrDestroy
                };
            }).call(this)
        }).call(this, require('_process'))
    }, {
        "_process": 9
    }],
    25: [function(require, module, exports) {
        // Ported from https://github.com/mafintosh/end-of-stream with
        // permission from the author, Mathias Buus (@mafintosh).

        'use strict';

        const ERR_STREAM_PREMATURE_CLOSE = require('../../../errors').codes.ERR_STREAM_PREMATURE_CLOSE;

        function once(callback) {
            let called = false;
            return function() {
                if (called) return;
                called = true;
                for (var _len = arguments.length, args = new Array(_len), _key = 0; _key < _len; _key++) {
                    args[_key] = arguments[_key];
                }
                callback.apply(this, args);
            };
        }

        function noop() {}

        function isRequest(stream) {
            return stream.setHeader && typeof stream.abort === 'function';
        }

        function eos(stream, opts, callback) {
            if (typeof opts === 'function') return eos(stream, null, opts);
            if (!opts) opts = {};
            callback = once(callback || noop);
            let readable = opts.readable || opts.readable !== false && stream.readable;
            let writable = opts.writable || opts.writable !== false && stream.writable;
            const onlegacyfinish = () => {
                if (!stream.writable) onfinish();
            };
            var writableEnded = stream._writableState && stream._writableState.finished;
            const onfinish = () => {
                writable = false;
                writableEnded = true;
                if (!readable) callback.call(stream);
            };
            var readableEnded = stream._readableState && stream._readableState.endEmitted;
            const onend = () => {
                readable = false;
                readableEnded = true;
                if (!writable) callback.call(stream);
            };
            const onerror = err => {
                callback.call(stream, err);
            };
            const onclose = () => {
                let err;
                if (readable && !readableEnded) {
                    if (!stream._readableState || !stream._readableState.ended) err = new ERR_STREAM_PREMATURE_CLOSE();
                    return callback.call(stream, err);
                }
                if (writable && !writableEnded) {
                    if (!stream._writableState || !stream._writableState.ended) err = new ERR_STREAM_PREMATURE_CLOSE();
                    return callback.call(stream, err);
                }
            };
            const onrequest = () => {
                stream.req.on('finish', onfinish);
            };
            if (isRequest(stream)) {
                stream.on('complete', onfinish);
                stream.on('abort', onclose);
                if (stream.req) onrequest();
                else stream.on('request', onrequest);
            } else if (writable && !stream._writableState) {
                // legacy streams
                stream.on('end', onlegacyfinish);
                stream.on('close', onlegacyfinish);
            }
            stream.on('end', onend);
            stream.on('finish', onfinish);
            if (opts.error !== false) stream.on('error', onerror);
            stream.on('close', onclose);
            return function() {
                stream.removeListener('complete', onfinish);
                stream.removeListener('abort', onclose);
                stream.removeListener('request', onrequest);
                if (stream.req) stream.req.removeListener('finish', onfinish);
                stream.removeListener('end', onlegacyfinish);
                stream.removeListener('close', onlegacyfinish);
                stream.removeListener('finish', onfinish);
                stream.removeListener('end', onend);
                stream.removeListener('error', onerror);
                stream.removeListener('close', onclose);
            };
        }
        module.exports = eos;
    }, {
        "../../../errors": 16
    }],
    26: [function(require, module, exports) {
        module.exports = function() {
            throw new Error('Readable.from is not available in the browser')
        };

    }, {}],
    27: [function(require, module, exports) {
        // Ported from https://github.com/mafintosh/pump with
        // permission from the author, Mathias Buus (@mafintosh).

        'use strict';

        let eos;

        function once(callback) {
            let called = false;
            return function() {
                if (called) return;
                called = true;
                callback(...arguments);
            };
        }
        const _require$codes = require('../../../errors').codes,
            ERR_MISSING_ARGS = _require$codes.ERR_MISSING_ARGS,
            ERR_STREAM_DESTROYED = _require$codes.ERR_STREAM_DESTROYED;

        function noop(err) {
            // Rethrow the error if it exists to avoid swallowing it
            if (err) throw err;
        }

        function isRequest(stream) {
            return stream.setHeader && typeof stream.abort === 'function';
        }

        function destroyer(stream, reading, writing, callback) {
            callback = once(callback);
            let closed = false;
            stream.on('close', () => {
                closed = true;
            });
            if (eos === undefined) eos = require('./end-of-stream');
            eos(stream, {
                readable: reading,
                writable: writing
            }, err => {
                if (err) return callback(err);
                closed = true;
                callback();
            });
            let destroyed = false;
            return err => {
                if (closed) return;
                if (destroyed) return;
                destroyed = true;

                // request.destroy just do .end - .abort is what we want
                if (isRequest(stream)) return stream.abort();
                if (typeof stream.destroy === 'function') return stream.destroy();
                callback(err || new ERR_STREAM_DESTROYED('pipe'));
            };
        }

        function call(fn) {
            fn();
        }

        function pipe(from, to) {
            return from.pipe(to);
        }

        function popCallback(streams) {
            if (!streams.length) return noop;
            if (typeof streams[streams.length - 1] !== 'function') return noop;
            return streams.pop();
        }

        function pipeline() {
            for (var _len = arguments.length, streams = new Array(_len), _key = 0; _key < _len; _key++) {
                streams[_key] = arguments[_key];
            }
            const callback = popCallback(streams);
            if (Array.isArray(streams[0])) streams = streams[0];
            if (streams.length < 2) {
                throw new ERR_MISSING_ARGS('streams');
            }
            let error;
            const destroys = streams.map(function(stream, i) {
                const reading = i < streams.length - 1;
                const writing = i > 0;
                return destroyer(stream, reading, writing, function(err) {
                    if (!error) error = err;
                    if (err) destroys.forEach(call);
                    if (reading) return;
                    destroys.forEach(call);
                    callback(error);
                });
            });
            return streams.reduce(pipe);
        }
        module.exports = pipeline;
    }, {
        "../../../errors": 16,
        "./end-of-stream": 25
    }],
    28: [function(require, module, exports) {
        'use strict';

        const ERR_INVALID_OPT_VALUE = require('../../../errors').codes.ERR_INVALID_OPT_VALUE;

        function highWaterMarkFrom(options, isDuplex, duplexKey) {
            return options.highWaterMark != null ? options.highWaterMark : isDuplex ? options[duplexKey] : null;
        }

        function getHighWaterMark(state, options, duplexKey, isDuplex) {
            const hwm = highWaterMarkFrom(options, isDuplex, duplexKey);
            if (hwm != null) {
                if (!(isFinite(hwm) && Math.floor(hwm) === hwm) || hwm < 0) {
                    const name = isDuplex ? duplexKey : 'highWaterMark';
                    throw new ERR_INVALID_OPT_VALUE(name, hwm);
                }
                return Math.floor(hwm);
            }

            // Default value
            return state.objectMode ? 16 : 16 * 1024;
        }
        module.exports = {
            getHighWaterMark
        };
    }, {
        "../../../errors": 16
    }],
    29: [function(require, module, exports) {
        module.exports = require('events').EventEmitter;

    }, {
        "events": 5
    }],
    30: [function(require, module, exports) {
        (function(global) {
            (function() {
                var ClientRequest = require('./lib/request')
                var response = require('./lib/response')
                var extend = require('xtend')
                var statusCodes = require('builtin-status-codes')
                var url = require('url')

                var http = exports

                http.request = function(opts, cb) {
                    if (typeof opts === 'string')
                        opts = url.parse(opts)
                    else
                        opts = extend(opts)

                    // Normally, the page is loaded from http or https, so not specifying a protocol
                    // will result in a (valid) protocol-relative url. However, this won't work if
                    // the protocol is something else, like 'file:'
                    var defaultProtocol = global.location.protocol.search(/^https?:$/) === -1 ? 'http:' : ''

                    var protocol = opts.protocol || defaultProtocol
                    var host = opts.hostname || opts.host
                    var port = opts.port
                    var path = opts.path || '/'

                    // Necessary for IPv6 addresses
                    if (host && host.indexOf(':') !== -1)
                        host = '[' + host + ']'

                    // This may be a relative url. The browser should always be able to interpret it correctly.
                    opts.url = (host ? (protocol + '//' + host) : '') + (port ? ':' + port : '') + path
                    opts.method = (opts.method || 'GET').toUpperCase()
                    opts.headers = opts.headers || {}

                    // Also valid opts.auth, opts.mode

                    var req = new ClientRequest(opts)
                    if (cb)
                        req.on('response', cb)
                    return req
                }

                http.get = function get(opts, cb) {
                    var req = http.request(opts, cb)
                    req.end()
                    return req
                }

                http.ClientRequest = ClientRequest
                http.IncomingMessage = response.IncomingMessage

                http.Agent = function() {}
                http.Agent.defaultMaxSockets = 4

                http.globalAgent = new http.Agent()

                http.STATUS_CODES = statusCodes

                http.METHODS = [
                    'CHECKOUT',
                    'CONNECT',
                    'COPY',
                    'DELETE',
                    'GET',
                    'HEAD',
                    'LOCK',
                    'M-SEARCH',
                    'MERGE',
                    'MKACTIVITY',
                    'MKCOL',
                    'MOVE',
                    'NOTIFY',
                    'OPTIONS',
                    'PATCH',
                    'POST',
                    'PROPFIND',
                    'PROPPATCH',
                    'PURGE',
                    'PUT',
                    'REPORT',
                    'SEARCH',
                    'SUBSCRIBE',
                    'TRACE',
                    'UNLOCK',
                    'UNSUBSCRIBE'
                ]
            }).call(this)
        }).call(this, typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
    }, {
        "./lib/request": 32,
        "./lib/response": 33,
        "builtin-status-codes": 4,
        "url": 51,
        "xtend": 55
    }],
    31: [function(require, module, exports) {
        (function(global) {
            (function() {
                exports.fetch = isFunction(global.fetch) && isFunction(global.ReadableStream)

                exports.writableStream = isFunction(global.WritableStream)

                exports.abortController = isFunction(global.AbortController)

                // The xhr request to example.com may violate some restrictive CSP configurations,
                // so if we're running in a browser that supports `fetch`, avoid calling getXHR()
                // and assume support for certain features below.
                var xhr

                function getXHR() {
                    // Cache the xhr value
                    if (xhr !== undefined) return xhr

                    if (global.XMLHttpRequest) {
                        xhr = new global.XMLHttpRequest()
                        // If XDomainRequest is available (ie only, where xhr might not work
                        // cross domain), use the page location. Otherwise use example.com
                        // Note: this doesn't actually make an http request.
                        try {
                            xhr.open('GET', global.XDomainRequest ? '/' : 'https://example.com')
                        } catch (e) {
                            xhr = null
                        }
                    } else {
                        // Service workers don't have XHR
                        xhr = null
                    }
                    return xhr
                }

                function checkTypeSupport(type) {
                    var xhr = getXHR()
                    if (!xhr) return false
                    try {
                        xhr.responseType = type
                        return xhr.responseType === type
                    } catch (e) {}
                    return false
                }

                // If fetch is supported, then arraybuffer will be supported too. Skip calling
                // checkTypeSupport(), since that calls getXHR().
                exports.arraybuffer = exports.fetch || checkTypeSupport('arraybuffer')

                // These next two tests unavoidably show warnings in Chrome. Since fetch will always
                // be used if it's available, just return false for these to avoid the warnings.
                exports.msstream = !exports.fetch && checkTypeSupport('ms-stream')
                exports.mozchunkedarraybuffer = !exports.fetch && checkTypeSupport('moz-chunked-arraybuffer')

                // If fetch is supported, then overrideMimeType will be supported too. Skip calling
                // getXHR().
                exports.overrideMimeType = exports.fetch || (getXHR() ? isFunction(getXHR().overrideMimeType) : false)

                function isFunction(value) {
                    return typeof value === 'function'
                }

                xhr = null // Help gc

            }).call(this)
        }).call(this, typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
    }, {}],
    32: [function(require, module, exports) {
        (function(process, global, Buffer) {
            (function() {
                var capability = require('./capability')
                var inherits = require('inherits')
                var response = require('./response')
                var stream = require('readable-stream')

                var IncomingMessage = response.IncomingMessage
                var rStates = response.readyStates

                function decideMode(preferBinary, useFetch) {
                    if (capability.fetch && useFetch) {
                        return 'fetch'
                    } else if (capability.mozchunkedarraybuffer) {
                        return 'moz-chunked-arraybuffer'
                    } else if (capability.msstream) {
                        return 'ms-stream'
                    } else if (capability.arraybuffer && preferBinary) {
                        return 'arraybuffer'
                    } else {
                        return 'text'
                    }
                }

                var ClientRequest = module.exports = function(opts) {
                    var self = this
                    stream.Writable.call(self)

                    self._opts = opts
                    self._body = []
                    self._headers = {}
                    if (opts.auth)
                        self.setHeader('Authorization', 'Basic ' + Buffer.from(opts.auth).toString('base64'))
                    Object.keys(opts.headers).forEach(function(name) {
                        self.setHeader(name, opts.headers[name])
                    })

                    var preferBinary
                    var useFetch = true
                    if (opts.mode === 'disable-fetch' || ('requestTimeout' in opts && !capability.abortController)) {
                        // If the use of XHR should be preferred. Not typically needed.
                        useFetch = false
                        preferBinary = true
                    } else if (opts.mode === 'prefer-streaming') {
                        // If streaming is a high priority but binary compatibility and
                        // the accuracy of the 'content-type' header aren't
                        preferBinary = false
                    } else if (opts.mode === 'allow-wrong-content-type') {
                        // If streaming is more important than preserving the 'content-type' header
                        preferBinary = !capability.overrideMimeType
                    } else if (!opts.mode || opts.mode === 'default' || opts.mode === 'prefer-fast') {
                        // Use binary if text streaming may corrupt data or the content-type header, or for speed
                        preferBinary = true
                    } else {
                        throw new Error('Invalid value for opts.mode')
                    }
                    self._mode = decideMode(preferBinary, useFetch)
                    self._fetchTimer = null
                    self._socketTimeout = null
                    self._socketTimer = null

                    self.on('finish', function() {
                        self._onFinish()
                    })
                }

                inherits(ClientRequest, stream.Writable)

                ClientRequest.prototype.setHeader = function(name, value) {
                    var self = this
                    var lowerName = name.toLowerCase()
                    // This check is not necessary, but it prevents warnings from browsers about setting unsafe
                    // headers. To be honest I'm not entirely sure hiding these warnings is a good thing, but
                    // http-browserify did it, so I will too.
                    if (unsafeHeaders.indexOf(lowerName) !== -1)
                        return

                    self._headers[lowerName] = {
                        name: name,
                        value: value
                    }
                }

                ClientRequest.prototype.getHeader = function(name) {
                    var header = this._headers[name.toLowerCase()]
                    if (header)
                        return header.value
                    return null
                }

                ClientRequest.prototype.removeHeader = function(name) {
                    var self = this
                    delete self._headers[name.toLowerCase()]
                }

                ClientRequest.prototype._onFinish = function() {
                    var self = this

                    if (self._destroyed)
                        return
                    var opts = self._opts

                    if ('timeout' in opts && opts.timeout !== 0) {
                        self.setTimeout(opts.timeout)
                    }

                    var headersObj = self._headers
                    var body = null
                    if (opts.method !== 'GET' && opts.method !== 'HEAD') {
                        body = new Blob(self._body, {
                            type: (headersObj['content-type'] || {}).value || ''
                        });
                    }

                    // create flattened list of headers
                    var headersList = []
                    Object.keys(headersObj).forEach(function(keyName) {
                        var name = headersObj[keyName].name
                        var value = headersObj[keyName].value
                        if (Array.isArray(value)) {
                            value.forEach(function(v) {
                                headersList.push([name, v])
                            })
                        } else {
                            headersList.push([name, value])
                        }
                    })

                    if (self._mode === 'fetch') {
                        var signal = null
                        if (capability.abortController) {
                            var controller = new AbortController()
                            signal = controller.signal
                            self._fetchAbortController = controller

                            if ('requestTimeout' in opts && opts.requestTimeout !== 0) {
                                self._fetchTimer = global.setTimeout(function() {
                                    self.emit('requestTimeout')
                                    if (self._fetchAbortController)
                                        self._fetchAbortController.abort()
                                }, opts.requestTimeout)
                            }
                        }

                        global.fetch(self._opts.url, {
                            method: self._opts.method,
                            headers: headersList,
                            body: body || undefined,
                            mode: 'cors',
                            credentials: opts.withCredentials ? 'include' : 'same-origin',
                            signal: signal
                        }).then(function(response) {
                            self._fetchResponse = response
                            self._resetTimers(false)
                            self._connect()
                        }, function(reason) {
                            self._resetTimers(true)
                            if (!self._destroyed)
                                self.emit('error', reason)
                        })
                    } else {
                        var xhr = self._xhr = new global.XMLHttpRequest()
                        try {
                            xhr.open(self._opts.method, self._opts.url, true)
                        } catch (err) {
                            process.nextTick(function() {
                                self.emit('error', err)
                            })
                            return
                        }

                        // Can't set responseType on really old browsers
                        if ('responseType' in xhr)
                            xhr.responseType = self._mode

                        if ('withCredentials' in xhr)
                            xhr.withCredentials = !!opts.withCredentials

                        if (self._mode === 'text' && 'overrideMimeType' in xhr)
                            xhr.overrideMimeType('text/plain; charset=x-user-defined')

                        if ('requestTimeout' in opts) {
                            xhr.timeout = opts.requestTimeout
                            xhr.ontimeout = function() {
                                self.emit('requestTimeout')
                            }
                        }

                        headersList.forEach(function(header) {
                            xhr.setRequestHeader(header[0], header[1])
                        })

                        self._response = null
                        xhr.onreadystatechange = function() {
                            switch (xhr.readyState) {
                                case rStates.LOADING:
                                case rStates.DONE:
                                    self._onXHRProgress()
                                    break
                            }
                        }
                        // Necessary for streaming in Firefox, since xhr.response is ONLY defined
                        // in onprogress, not in onreadystatechange with xhr.readyState = 3
                        if (self._mode === 'moz-chunked-arraybuffer') {
                            xhr.onprogress = function() {
                                self._onXHRProgress()
                            }
                        }

                        xhr.onerror = function() {
                            if (self._destroyed)
                                return
                            self._resetTimers(true)
                            self.emit('error', new Error('XHR error'))
                        }

                        try {
                            xhr.send(body)
                        } catch (err) {
                            process.nextTick(function() {
                                self.emit('error', err)
                            })
                            return
                        }
                    }
                }

                /**
                 * Checks if xhr.status is readable and non-zero, indicating no error.
                 * Even though the spec says it should be available in readyState 3,
                 * accessing it throws an exception in IE8
                 */
                function statusValid(xhr) {
                    try {
                        var status = xhr.status
                        return (status !== null && status !== 0)
                    } catch (e) {
                        return false
                    }
                }

                ClientRequest.prototype._onXHRProgress = function() {
                    var self = this

                    self._resetTimers(false)

                    if (!statusValid(self._xhr) || self._destroyed)
                        return

                    if (!self._response)
                        self._connect()

                    self._response._onXHRProgress(self._resetTimers.bind(self))
                }

                ClientRequest.prototype._connect = function() {
                    var self = this

                    if (self._destroyed)
                        return

                    self._response = new IncomingMessage(self._xhr, self._fetchResponse, self._mode, self._resetTimers.bind(self))
                    self._response.on('error', function(err) {
                        self.emit('error', err)
                    })

                    self.emit('response', self._response)
                }

                ClientRequest.prototype._write = function(chunk, encoding, cb) {
                    var self = this

                    self._body.push(chunk)
                    cb()
                }

                ClientRequest.prototype._resetTimers = function(done) {
                    var self = this

                    global.clearTimeout(self._socketTimer)
                    self._socketTimer = null

                    if (done) {
                        global.clearTimeout(self._fetchTimer)
                        self._fetchTimer = null
                    } else if (self._socketTimeout) {
                        self._socketTimer = global.setTimeout(function() {
                            self.emit('timeout')
                        }, self._socketTimeout)
                    }
                }

                ClientRequest.prototype.abort = ClientRequest.prototype.destroy = function(err) {
                    var self = this
                    self._destroyed = true
                    self._resetTimers(true)
                    if (self._response)
                        self._response._destroyed = true
                    if (self._xhr)
                        self._xhr.abort()
                    else if (self._fetchAbortController)
                        self._fetchAbortController.abort()

                    if (err)
                        self.emit('error', err)
                }

                ClientRequest.prototype.end = function(data, encoding, cb) {
                    var self = this
                    if (typeof data === 'function') {
                        cb = data
                        data = undefined
                    }

                    stream.Writable.prototype.end.call(self, data, encoding, cb)
                }

                ClientRequest.prototype.setTimeout = function(timeout, cb) {
                    var self = this

                    if (cb)
                        self.once('timeout', cb)

                    self._socketTimeout = timeout
                    self._resetTimers(false)
                }

                ClientRequest.prototype.flushHeaders = function() {}
                ClientRequest.prototype.setNoDelay = function() {}
                ClientRequest.prototype.setSocketKeepAlive = function() {}

                // Taken from http://www.w3.org/TR/XMLHttpRequest/#the-setrequestheader%28%29-method
                var unsafeHeaders = [
                    'accept-charset',
                    'accept-encoding',
                    'access-control-request-headers',
                    'access-control-request-method',
                    'connection',
                    'content-length',
                    'cookie',
                    'cookie2',
                    'date',
                    'dnt',
                    'expect',
                    'host',
                    'keep-alive',
                    'origin',
                    'referer',
                    'te',
                    'trailer',
                    'transfer-encoding',
                    'upgrade',
                    'via'
                ]

            }).call(this)
        }).call(this, require('_process'), typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {}, require("buffer").Buffer)
    }, {
        "./capability": 31,
        "./response": 33,
        "_process": 9,
        "buffer": 3,
        "inherits": 8,
        "readable-stream": 48
    }],
    33: [function(require, module, exports) {
        (function(process, global, Buffer) {
            (function() {
                var capability = require('./capability')
                var inherits = require('inherits')
                var stream = require('readable-stream')

                var rStates = exports.readyStates = {
                    UNSENT: 0,
                    OPENED: 1,
                    HEADERS_RECEIVED: 2,
                    LOADING: 3,
                    DONE: 4
                }

                var IncomingMessage = exports.IncomingMessage = function(xhr, response, mode, resetTimers) {
                    var self = this
                    stream.Readable.call(self)

                    self._mode = mode
                    self.headers = {}
                    self.rawHeaders = []
                    self.trailers = {}
                    self.rawTrailers = []

                    // Fake the 'close' event, but only once 'end' fires
                    self.on('end', function() {
                        // The nextTick is necessary to prevent the 'request' module from causing an infinite loop
                        process.nextTick(function() {
                            self.emit('close')
                        })
                    })

                    if (mode === 'fetch') {
                        self._fetchResponse = response

                        self.url = response.url
                        self.statusCode = response.status
                        self.statusMessage = response.statusText

                        response.headers.forEach(function(header, key) {
                            self.headers[key.toLowerCase()] = header
                            self.rawHeaders.push(key, header)
                        })

                        if (capability.writableStream) {
                            var writable = new WritableStream({
                                write: function(chunk) {
                                    resetTimers(false)
                                    return new Promise(function(resolve, reject) {
                                        if (self._destroyed) {
                                            reject()
                                        } else if (self.push(Buffer.from(chunk))) {
                                            resolve()
                                        } else {
                                            self._resumeFetch = resolve
                                        }
                                    })
                                },
                                close: function() {
                                    resetTimers(true)
                                    if (!self._destroyed)
                                        self.push(null)
                                },
                                abort: function(err) {
                                    resetTimers(true)
                                    if (!self._destroyed)
                                        self.emit('error', err)
                                }
                            })

                            try {
                                response.body.pipeTo(writable).catch(function(err) {
                                    resetTimers(true)
                                    if (!self._destroyed)
                                        self.emit('error', err)
                                })
                                return
                            } catch (e) {} // pipeTo method isn't defined. Can't find a better way to feature test this
                        }
                        // fallback for when writableStream or pipeTo aren't available
                        var reader = response.body.getReader()

                        function read() {
                            reader.read().then(function(result) {
                                if (self._destroyed)
                                    return
                                resetTimers(result.done)
                                if (result.done) {
                                    self.push(null)
                                    return
                                }
                                self.push(Buffer.from(result.value))
                                read()
                            }).catch(function(err) {
                                resetTimers(true)
                                if (!self._destroyed)
                                    self.emit('error', err)
                            })
                        }
                        read()
                    } else {
                        self._xhr = xhr
                        self._pos = 0

                        self.url = xhr.responseURL
                        self.statusCode = xhr.status
                        self.statusMessage = xhr.statusText
                        var headers = xhr.getAllResponseHeaders().split(/\r?\n/)
                        headers.forEach(function(header) {
                            var matches = header.match(/^([^:]+):\s*(.*)/)
                            if (matches) {
                                var key = matches[1].toLowerCase()
                                if (key === 'set-cookie') {
                                    if (self.headers[key] === undefined) {
                                        self.headers[key] = []
                                    }
                                    self.headers[key].push(matches[2])
                                } else if (self.headers[key] !== undefined) {
                                    self.headers[key] += ', ' + matches[2]
                                } else {
                                    self.headers[key] = matches[2]
                                }
                                self.rawHeaders.push(matches[1], matches[2])
                            }
                        })

                        self._charset = 'x-user-defined'
                        if (!capability.overrideMimeType) {
                            var mimeType = self.rawHeaders['mime-type']
                            if (mimeType) {
                                var charsetMatch = mimeType.match(/;\s*charset=([^;])(;|$)/)
                                if (charsetMatch) {
                                    self._charset = charsetMatch[1].toLowerCase()
                                }
                            }
                            if (!self._charset)
                                self._charset = 'utf-8' // best guess
                        }
                    }
                }

                inherits(IncomingMessage, stream.Readable)

                IncomingMessage.prototype._read = function() {
                    var self = this

                    var resolve = self._resumeFetch
                    if (resolve) {
                        self._resumeFetch = null
                        resolve()
                    }
                }

                IncomingMessage.prototype._onXHRProgress = function(resetTimers) {
                    var self = this

                    var xhr = self._xhr

                    var response = null
                    switch (self._mode) {
                        case 'text':
                            response = xhr.responseText
                            if (response.length > self._pos) {
                                var newData = response.substr(self._pos)
                                if (self._charset === 'x-user-defined') {
                                    var buffer = Buffer.alloc(newData.length)
                                    for (var i = 0; i < newData.length; i++)
                                        buffer[i] = newData.charCodeAt(i) & 0xff

                                    self.push(buffer)
                                } else {
                                    self.push(newData, self._charset)
                                }
                                self._pos = response.length
                            }
                            break
                        case 'arraybuffer':
                            if (xhr.readyState !== rStates.DONE || !xhr.response)
                                break
                            response = xhr.response
                            self.push(Buffer.from(new Uint8Array(response)))
                            break
                        case 'moz-chunked-arraybuffer': // take whole
                            response = xhr.response
                            if (xhr.readyState !== rStates.LOADING || !response)
                                break
                            self.push(Buffer.from(new Uint8Array(response)))
                            break
                        case 'ms-stream':
                            response = xhr.response
                            if (xhr.readyState !== rStates.LOADING)
                                break
                            var reader = new global.MSStreamReader()
                            reader.onprogress = function() {
                                if (reader.result.byteLength > self._pos) {
                                    self.push(Buffer.from(new Uint8Array(reader.result.slice(self._pos))))
                                    self._pos = reader.result.byteLength
                                }
                            }
                            reader.onload = function() {
                                resetTimers(true)
                                self.push(null)
                            }
                            // reader.onerror = ??? // TODO: this
                            reader.readAsArrayBuffer(response)
                            break
                    }

                    // The ms-stream case handles end separately in reader.onload()
                    if (self._xhr.readyState === rStates.DONE && self._mode !== 'ms-stream') {
                        resetTimers(true)
                        self.push(null)
                    }
                }

            }).call(this)
        }).call(this, require('_process'), typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {}, require("buffer").Buffer)
    }, {
        "./capability": 31,
        "_process": 9,
        "buffer": 3,
        "inherits": 8,
        "readable-stream": 48
    }],
    34: [function(require, module, exports) {
        arguments[4][16][0].apply(exports, arguments)
    }, {
        "dup": 16
    }],
    35: [function(require, module, exports) {
        arguments[4][17][0].apply(exports, arguments)
    }, {
        "./_stream_readable": 37,
        "./_stream_writable": 39,
        "_process": 9,
        "dup": 17,
        "inherits": 8
    }],
    36: [function(require, module, exports) {
        arguments[4][18][0].apply(exports, arguments)
    }, {
        "./_stream_transform": 38,
        "dup": 18,
        "inherits": 8
    }],
    37: [function(require, module, exports) {
        arguments[4][19][0].apply(exports, arguments)
    }, {
        "../errors": 34,
        "./_stream_duplex": 35,
        "./internal/streams/async_iterator": 40,
        "./internal/streams/buffer_list": 41,
        "./internal/streams/destroy": 42,
        "./internal/streams/from": 44,
        "./internal/streams/state": 46,
        "./internal/streams/stream": 47,
        "_process": 9,
        "buffer": 3,
        "dup": 19,
        "events": 5,
        "inherits": 8,
        "string_decoder/": 49,
        "util": 2
    }],
    38: [function(require, module, exports) {
        arguments[4][20][0].apply(exports, arguments)
    }, {
        "../errors": 34,
        "./_stream_duplex": 35,
        "dup": 20,
        "inherits": 8
    }],
    39: [function(require, module, exports) {
        arguments[4][21][0].apply(exports, arguments)
    }, {
        "../errors": 34,
        "./_stream_duplex": 35,
        "./internal/streams/destroy": 42,
        "./internal/streams/state": 46,
        "./internal/streams/stream": 47,
        "_process": 9,
        "buffer": 3,
        "dup": 21,
        "inherits": 8,
        "util-deprecate": 53
    }],
    40: [function(require, module, exports) {
        arguments[4][22][0].apply(exports, arguments)
    }, {
        "./end-of-stream": 43,
        "_process": 9,
        "dup": 22
    }],
    41: [function(require, module, exports) {
        arguments[4][23][0].apply(exports, arguments)
    }, {
        "buffer": 3,
        "dup": 23,
        "util": 2
    }],
    42: [function(require, module, exports) {
        arguments[4][24][0].apply(exports, arguments)
    }, {
        "_process": 9,
        "dup": 24
    }],
    43: [function(require, module, exports) {
        arguments[4][25][0].apply(exports, arguments)
    }, {
        "../../../errors": 34,
        "dup": 25
    }],
    44: [function(require, module, exports) {
        arguments[4][26][0].apply(exports, arguments)
    }, {
        "dup": 26
    }],
    45: [function(require, module, exports) {
        arguments[4][27][0].apply(exports, arguments)
    }, {
        "../../../errors": 34,
        "./end-of-stream": 43,
        "dup": 27
    }],
    46: [function(require, module, exports) {
        arguments[4][28][0].apply(exports, arguments)
    }, {
        "../../../errors": 34,
        "dup": 28
    }],
    47: [function(require, module, exports) {
        arguments[4][29][0].apply(exports, arguments)
    }, {
        "dup": 29,
        "events": 5
    }],
    48: [function(require, module, exports) {
        exports = module.exports = require('./lib/_stream_readable.js');
        exports.Stream = exports;
        exports.Readable = exports;
        exports.Writable = require('./lib/_stream_writable.js');
        exports.Duplex = require('./lib/_stream_duplex.js');
        exports.Transform = require('./lib/_stream_transform.js');
        exports.PassThrough = require('./lib/_stream_passthrough.js');
        exports.finished = require('./lib/internal/streams/end-of-stream.js');
        exports.pipeline = require('./lib/internal/streams/pipeline.js');

    }, {
        "./lib/_stream_duplex.js": 35,
        "./lib/_stream_passthrough.js": 36,
        "./lib/_stream_readable.js": 37,
        "./lib/_stream_transform.js": 38,
        "./lib/_stream_writable.js": 39,
        "./lib/internal/streams/end-of-stream.js": 43,
        "./lib/internal/streams/pipeline.js": 45
    }],
    49: [function(require, module, exports) {
        // Copyright Joyent, Inc. and other Node contributors.
        //
        // Permission is hereby granted, free of charge, to any person obtaining a
        // copy of this software and associated documentation files (the
        // "Software"), to deal in the Software without restriction, including
        // without limitation the rights to use, copy, modify, merge, publish,
        // distribute, sublicense, and/or sell copies of the Software, and to permit
        // persons to whom the Software is furnished to do so, subject to the
        // following conditions:
        //
        // The above copyright notice and this permission notice shall be included
        // in all copies or substantial portions of the Software.
        //
        // THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
        // OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
        // MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
        // NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
        // DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
        // OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
        // USE OR OTHER DEALINGS IN THE SOFTWARE.

        'use strict';

        /*<replacement>*/

        var Buffer = require('safe-buffer').Buffer;
        /*</replacement>*/

        var isEncoding = Buffer.isEncoding || function(encoding) {
            encoding = '' + encoding;
            switch (encoding && encoding.toLowerCase()) {
                case 'hex':
                case 'utf8':
                case 'utf-8':
                case 'ascii':
                case 'binary':
                case 'base64':
                case 'ucs2':
                case 'ucs-2':
                case 'utf16le':
                case 'utf-16le':
                case 'raw':
                    return true;
                default:
                    return false;
            }
        };

        function _normalizeEncoding(enc) {
            if (!enc) return 'utf8';
            var retried;
            while (true) {
                switch (enc) {
                    case 'utf8':
                    case 'utf-8':
                        return 'utf8';
                    case 'ucs2':
                    case 'ucs-2':
                    case 'utf16le':
                    case 'utf-16le':
                        return 'utf16le';
                    case 'latin1':
                    case 'binary':
                        return 'latin1';
                    case 'base64':
                    case 'ascii':
                    case 'hex':
                        return enc;
                    default:
                        if (retried) return; // undefined
                        enc = ('' + enc).toLowerCase();
                        retried = true;
                }
            }
        };

        // Do not cache `Buffer.isEncoding` when checking encoding names as some
        // modules monkey-patch it to support additional encodings
        function normalizeEncoding(enc) {
            var nenc = _normalizeEncoding(enc);
            if (typeof nenc !== 'string' && (Buffer.isEncoding === isEncoding || !isEncoding(enc))) throw new Error('Unknown encoding: ' + enc);
            return nenc || enc;
        }

        // StringDecoder provides an interface for efficiently splitting a series of
        // buffers into a series of JS strings without breaking apart multi-byte
        // characters.
        exports.StringDecoder = StringDecoder;

        function StringDecoder(encoding) {
            this.encoding = normalizeEncoding(encoding);
            var nb;
            switch (this.encoding) {
                case 'utf16le':
                    this.text = utf16Text;
                    this.end = utf16End;
                    nb = 4;
                    break;
                case 'utf8':
                    this.fillLast = utf8FillLast;
                    nb = 4;
                    break;
                case 'base64':
                    this.text = base64Text;
                    this.end = base64End;
                    nb = 3;
                    break;
                default:
                    this.write = simpleWrite;
                    this.end = simpleEnd;
                    return;
            }
            this.lastNeed = 0;
            this.lastTotal = 0;
            this.lastChar = Buffer.allocUnsafe(nb);
        }

        StringDecoder.prototype.write = function(buf) {
            if (buf.length === 0) return '';
            var r;
            var i;
            if (this.lastNeed) {
                r = this.fillLast(buf);
                if (r === undefined) return '';
                i = this.lastNeed;
                this.lastNeed = 0;
            } else {
                i = 0;
            }
            if (i < buf.length) return r ? r + this.text(buf, i) : this.text(buf, i);
            return r || '';
        };

        StringDecoder.prototype.end = utf8End;

        // Returns only complete characters in a Buffer
        StringDecoder.prototype.text = utf8Text;

        // Attempts to complete a partial non-UTF-8 character using bytes from a Buffer
        StringDecoder.prototype.fillLast = function(buf) {
            if (this.lastNeed <= buf.length) {
                buf.copy(this.lastChar, this.lastTotal - this.lastNeed, 0, this.lastNeed);
                return this.lastChar.toString(this.encoding, 0, this.lastTotal);
            }
            buf.copy(this.lastChar, this.lastTotal - this.lastNeed, 0, buf.length);
            this.lastNeed -= buf.length;
        };

        // Checks the type of a UTF-8 byte, whether it's ASCII, a leading byte, or a
        // continuation byte. If an invalid byte is detected, -2 is returned.
        function utf8CheckByte(byte) {
            if (byte <= 0x7F) return 0;
            else if (byte >> 5 === 0x06) return 2;
            else if (byte >> 4 === 0x0E) return 3;
            else if (byte >> 3 === 0x1E) return 4;
            return byte >> 6 === 0x02 ? -1 : -2;
        }

        // Checks at most 3 bytes at the end of a Buffer in order to detect an
        // incomplete multi-byte UTF-8 character. The total number of bytes (2, 3, or 4)
        // needed to complete the UTF-8 character (if applicable) are returned.
        function utf8CheckIncomplete(self, buf, i) {
            var j = buf.length - 1;
            if (j < i) return 0;
            var nb = utf8CheckByte(buf[j]);
            if (nb >= 0) {
                if (nb > 0) self.lastNeed = nb - 1;
                return nb;
            }
            if (--j < i || nb === -2) return 0;
            nb = utf8CheckByte(buf[j]);
            if (nb >= 0) {
                if (nb > 0) self.lastNeed = nb - 2;
                return nb;
            }
            if (--j < i || nb === -2) return 0;
            nb = utf8CheckByte(buf[j]);
            if (nb >= 0) {
                if (nb > 0) {
                    if (nb === 2) nb = 0;
                    else self.lastNeed = nb - 3;
                }
                return nb;
            }
            return 0;
        }

        // Validates as many continuation bytes for a multi-byte UTF-8 character as
        // needed or are available. If we see a non-continuation byte where we expect
        // one, we "replace" the validated continuation bytes we've seen so far with
        // a single UTF-8 replacement character ('\ufffd'), to match v8's UTF-8 decoding
        // behavior. The continuation byte check is included three times in the case
        // where all of the continuation bytes for a character exist in the same buffer.
        // It is also done this way as a slight performance increase instead of using a
        // loop.
        function utf8CheckExtraBytes(self, buf, p) {
            if ((buf[0] & 0xC0) !== 0x80) {
                self.lastNeed = 0;
                return '\ufffd';
            }
            if (self.lastNeed > 1 && buf.length > 1) {
                if ((buf[1] & 0xC0) !== 0x80) {
                    self.lastNeed = 1;
                    return '\ufffd';
                }
                if (self.lastNeed > 2 && buf.length > 2) {
                    if ((buf[2] & 0xC0) !== 0x80) {
                        self.lastNeed = 2;
                        return '\ufffd';
                    }
                }
            }
        }

        // Attempts to complete a multi-byte UTF-8 character using bytes from a Buffer.
        function utf8FillLast(buf) {
            var p = this.lastTotal - this.lastNeed;
            var r = utf8CheckExtraBytes(this, buf, p);
            if (r !== undefined) return r;
            if (this.lastNeed <= buf.length) {
                buf.copy(this.lastChar, p, 0, this.lastNeed);
                return this.lastChar.toString(this.encoding, 0, this.lastTotal);
            }
            buf.copy(this.lastChar, p, 0, buf.length);
            this.lastNeed -= buf.length;
        }

        // Returns all complete UTF-8 characters in a Buffer. If the Buffer ended on a
        // partial character, the character's bytes are buffered until the required
        // number of bytes are available.
        function utf8Text(buf, i) {
            var total = utf8CheckIncomplete(this, buf, i);
            if (!this.lastNeed) return buf.toString('utf8', i);
            this.lastTotal = total;
            var end = buf.length - (total - this.lastNeed);
            buf.copy(this.lastChar, 0, end);
            return buf.toString('utf8', i, end);
        }

        // For UTF-8, a replacement character is added when ending on a partial
        // character.
        function utf8End(buf) {
            var r = buf && buf.length ? this.write(buf) : '';
            if (this.lastNeed) return r + '\ufffd';
            return r;
        }

        // UTF-16LE typically needs two bytes per character, but even if we have an even
        // number of bytes available, we need to check if we end on a leading/high
        // surrogate. In that case, we need to wait for the next two bytes in order to
        // decode the last character properly.
        function utf16Text(buf, i) {
            if ((buf.length - i) % 2 === 0) {
                var r = buf.toString('utf16le', i);
                if (r) {
                    var c = r.charCodeAt(r.length - 1);
                    if (c >= 0xD800 && c <= 0xDBFF) {
                        this.lastNeed = 2;
                        this.lastTotal = 4;
                        this.lastChar[0] = buf[buf.length - 2];
                        this.lastChar[1] = buf[buf.length - 1];
                        return r.slice(0, -1);
                    }
                }
                return r;
            }
            this.lastNeed = 1;
            this.lastTotal = 2;
            this.lastChar[0] = buf[buf.length - 1];
            return buf.toString('utf16le', i, buf.length - 1);
        }

        // For UTF-16LE we do not explicitly append special replacement characters if we
        // end on a partial character, we simply let v8 handle that.
        function utf16End(buf) {
            var r = buf && buf.length ? this.write(buf) : '';
            if (this.lastNeed) {
                var end = this.lastTotal - this.lastNeed;
                return r + this.lastChar.toString('utf16le', 0, end);
            }
            return r;
        }

        function base64Text(buf, i) {
            var n = (buf.length - i) % 3;
            if (n === 0) return buf.toString('base64', i);
            this.lastNeed = 3 - n;
            this.lastTotal = 3;
            if (n === 1) {
                this.lastChar[0] = buf[buf.length - 1];
            } else {
                this.lastChar[0] = buf[buf.length - 2];
                this.lastChar[1] = buf[buf.length - 1];
            }
            return buf.toString('base64', i, buf.length - n);
        }

        function base64End(buf) {
            var r = buf && buf.length ? this.write(buf) : '';
            if (this.lastNeed) return r + this.lastChar.toString('base64', 0, 3 - this.lastNeed);
            return r;
        }

        // Pass bytes on through for single-byte encodings (e.g. ascii, latin1, hex)
        function simpleWrite(buf) {
            return buf.toString(this.encoding);
        }

        function simpleEnd(buf) {
            return buf && buf.length ? this.write(buf) : '';
        }
    }, {
        "safe-buffer": 14
    }],
    50: [function(require, module, exports) {
        (function(setImmediate, clearImmediate) {
            (function() {
                var nextTick = require('process/browser.js').nextTick;
                var apply = Function.prototype.apply;
                var slice = Array.prototype.slice;
                var immediateIds = {};
                var nextImmediateId = 0;

                // DOM APIs, for completeness

                exports.setTimeout = function() {
                    return new Timeout(apply.call(setTimeout, window, arguments), clearTimeout);
                };
                exports.setInterval = function() {
                    return new Timeout(apply.call(setInterval, window, arguments), clearInterval);
                };
                exports.clearTimeout =
                    exports.clearInterval = function(timeout) {
                        timeout.close();
                    };

                function Timeout(id, clearFn) {
                    this._id = id;
                    this._clearFn = clearFn;
                }
                Timeout.prototype.unref = Timeout.prototype.ref = function() {};
                Timeout.prototype.close = function() {
                    this._clearFn.call(window, this._id);
                };

                // Does not start the time, just sets up the members needed.
                exports.enroll = function(item, msecs) {
                    clearTimeout(item._idleTimeoutId);
                    item._idleTimeout = msecs;
                };

                exports.unenroll = function(item) {
                    clearTimeout(item._idleTimeoutId);
                    item._idleTimeout = -1;
                };

                exports._unrefActive = exports.active = function(item) {
                    clearTimeout(item._idleTimeoutId);

                    var msecs = item._idleTimeout;
                    if (msecs >= 0) {
                        item._idleTimeoutId = setTimeout(function onTimeout() {
                            if (item._onTimeout)
                                item._onTimeout();
                        }, msecs);
                    }
                };

                // That's not how node.js implements it but the exposed api is the same.
                exports.setImmediate = typeof setImmediate === "function" ? setImmediate : function(fn) {
                    var id = nextImmediateId++;
                    var args = arguments.length < 2 ? false : slice.call(arguments, 1);

                    immediateIds[id] = true;

                    nextTick(function onNextTick() {
                        if (immediateIds[id]) {
                            // fn.call() is faster so we optimize for the common use-case
                            // @see http://jsperf.com/call-apply-segu
                            if (args) {
                                fn.apply(null, args);
                            } else {
                                fn.call(null);
                            }
                            // Prevent ids from leaking
                            exports.clearImmediate(id);
                        }
                    });

                    return id;
                };

                exports.clearImmediate = typeof clearImmediate === "function" ? clearImmediate : function(id) {
                    delete immediateIds[id];
                };
            }).call(this)
        }).call(this, require("timers").setImmediate, require("timers").clearImmediate)
    }, {
        "process/browser.js": 9,
        "timers": 50
    }],
    51: [function(require, module, exports) {
        // Copyright Joyent, Inc. and other Node contributors.
        //
        // Permission is hereby granted, free of charge, to any person obtaining a
        // copy of this software and associated documentation files (the
        // "Software"), to deal in the Software without restriction, including
        // without limitation the rights to use, copy, modify, merge, publish,
        // distribute, sublicense, and/or sell copies of the Software, and to permit
        // persons to whom the Software is furnished to do so, subject to the
        // following conditions:
        //
        // The above copyright notice and this permission notice shall be included
        // in all copies or substantial portions of the Software.
        //
        // THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
        // OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
        // MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
        // NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
        // DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
        // OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
        // USE OR OTHER DEALINGS IN THE SOFTWARE.

        'use strict';

        var punycode = require('punycode');
        var util = require('./util');

        exports.parse = urlParse;
        exports.resolve = urlResolve;
        exports.resolveObject = urlResolveObject;
        exports.format = urlFormat;

        exports.Url = Url;

        function Url() {
            this.protocol = null;
            this.slashes = null;
            this.auth = null;
            this.host = null;
            this.port = null;
            this.hostname = null;
            this.hash = null;
            this.search = null;
            this.query = null;
            this.pathname = null;
            this.path = null;
            this.href = null;
        }

        // Reference: RFC 3986, RFC 1808, RFC 2396

        // define these here so at least they only have to be
        // compiled once on the first module load.
        var protocolPattern = /^([a-z0-9.+-]+:)/i,
            portPattern = /:[0-9]*$/,

            // Special case for a simple path URL
            simplePathPattern = /^(\/\/?(?!\/)[^\?\s]*)(\?[^\s]*)?$/,

            // RFC 2396: characters reserved for delimiting URLs.
            // We actually just auto-escape these.
            delims = ['<', '>', '"', '`', ' ', '\r', '\n', '\t'],

            // RFC 2396: characters not allowed for various reasons.
            unwise = ['{', '}', '|', '\\', '^', '`'].concat(delims),

            // Allowed by RFCs, but cause of XSS attacks.  Always escape these.
            autoEscape = ['\''].concat(unwise),
            // Characters that are never ever allowed in a hostname.
            // Note that any invalid chars are also handled, but these
            // are the ones that are *expected* to be seen, so we fast-path
            // them.
            nonHostChars = ['%', '/', '?', ';', '#'].concat(autoEscape),
            hostEndingChars = ['/', '?', '#'],
            hostnameMaxLen = 255,
            hostnamePartPattern = /^[+a-z0-9A-Z_-]{0,63}$/,
            hostnamePartStart = /^([+a-z0-9A-Z_-]{0,63})(.*)$/,
            // protocols that can allow "unsafe" and "unwise" chars.
            unsafeProtocol = {
                'javascript': true,
                'javascript:': true
            },
            // protocols that never have a hostname.
            hostlessProtocol = {
                'javascript': true,
                'javascript:': true
            },
            // protocols that always contain a // bit.
            slashedProtocol = {
                'http': true,
                'https': true,
                'ftp': true,
                'gopher': true,
                'file': true,
                'http:': true,
                'https:': true,
                'ftp:': true,
                'gopher:': true,
                'file:': true
            },
            querystring = require('querystring');

        function urlParse(url, parseQueryString, slashesDenoteHost) {
            if (url && util.isObject(url) && url instanceof Url) return url;

            var u = new Url;
            u.parse(url, parseQueryString, slashesDenoteHost);
            return u;
        }

        Url.prototype.parse = function(url, parseQueryString, slashesDenoteHost) {
            if (!util.isString(url)) {
                throw new TypeError("Parameter 'url' must be a string, not " + typeof url);
            }

            // Copy chrome, IE, opera backslash-handling behavior.
            // Back slashes before the query string get converted to forward slashes
            // See: https://code.google.com/p/chromium/issues/detail?id=25916
            var queryIndex = url.indexOf('?'),
                splitter =
                (queryIndex !== -1 && queryIndex < url.indexOf('#')) ? '?' : '#',
                uSplit = url.split(splitter),
                slashRegex = /\\/g;
            uSplit[0] = uSplit[0].replace(slashRegex, '/');
            url = uSplit.join(splitter);

            var rest = url;

            // trim before proceeding.
            // This is to support parse stuff like "  http://foo.com  \n"
            rest = rest.trim();

            if (!slashesDenoteHost && url.split('#').length === 1) {
                // Try fast path regexp
                var simplePath = simplePathPattern.exec(rest);
                if (simplePath) {
                    this.path = rest;
                    this.href = rest;
                    this.pathname = simplePath[1];
                    if (simplePath[2]) {
                        this.search = simplePath[2];
                        if (parseQueryString) {
                            this.query = querystring.parse(this.search.substr(1));
                        } else {
                            this.query = this.search.substr(1);
                        }
                    } else if (parseQueryString) {
                        this.search = '';
                        this.query = {};
                    }
                    return this;
                }
            }

            var proto = protocolPattern.exec(rest);
            if (proto) {
                proto = proto[0];
                var lowerProto = proto.toLowerCase();
                this.protocol = lowerProto;
                rest = rest.substr(proto.length);
            }

            // figure out if it's got a host
            // user@server is *always* interpreted as a hostname, and url
            // resolution will treat //foo/bar as host=foo,path=bar because that's
            // how the browser resolves relative URLs.
            if (slashesDenoteHost || proto || rest.match(/^\/\/[^@\/]+@[^@\/]+/)) {
                var slashes = rest.substr(0, 2) === '//';
                if (slashes && !(proto && hostlessProtocol[proto])) {
                    rest = rest.substr(2);
                    this.slashes = true;
                }
            }

            if (!hostlessProtocol[proto] &&
                (slashes || (proto && !slashedProtocol[proto]))) {

                // there's a hostname.
                // the first instance of /, ?, ;, or # ends the host.
                //
                // If there is an @ in the hostname, then non-host chars *are* allowed
                // to the left of the last @ sign, unless some host-ending character
                // comes *before* the @-sign.
                // URLs are obnoxious.
                //
                // ex:
                // http://a@b@c/ => user:a@b host:c
                // http://a@b?@c => user:a host:c path:/?@c

                // v0.12 TODO(isaacs): This is not quite how Chrome does things.
                // Review our test case against browsers more comprehensively.

                // find the first instance of any hostEndingChars
                var hostEnd = -1;
                for (var i = 0; i < hostEndingChars.length; i++) {
                    var hec = rest.indexOf(hostEndingChars[i]);
                    if (hec !== -1 && (hostEnd === -1 || hec < hostEnd))
                        hostEnd = hec;
                }

                // at this point, either we have an explicit point where the
                // auth portion cannot go past, or the last @ char is the decider.
                var auth, atSign;
                if (hostEnd === -1) {
                    // atSign can be anywhere.
                    atSign = rest.lastIndexOf('@');
                } else {
                    // atSign must be in auth portion.
                    // http://a@b/c@d => host:b auth:a path:/c@d
                    atSign = rest.lastIndexOf('@', hostEnd);
                }

                // Now we have a portion which is definitely the auth.
                // Pull that off.
                if (atSign !== -1) {
                    auth = rest.slice(0, atSign);
                    rest = rest.slice(atSign + 1);
                    this.auth = decodeURIComponent(auth);
                }

                // the host is the remaining to the left of the first non-host char
                hostEnd = -1;
                for (var i = 0; i < nonHostChars.length; i++) {
                    var hec = rest.indexOf(nonHostChars[i]);
                    if (hec !== -1 && (hostEnd === -1 || hec < hostEnd))
                        hostEnd = hec;
                }
                // if we still have not hit it, then the entire thing is a host.
                if (hostEnd === -1)
                    hostEnd = rest.length;

                this.host = rest.slice(0, hostEnd);
                rest = rest.slice(hostEnd);

                // pull out port.
                this.parseHost();

                // we've indicated that there is a hostname,
                // so even if it's empty, it has to be present.
                this.hostname = this.hostname || '';

                // if hostname begins with [ and ends with ]
                // assume that it's an IPv6 address.
                var ipv6Hostname = this.hostname[0] === '[' &&
                    this.hostname[this.hostname.length - 1] === ']';

                // validate a little.
                if (!ipv6Hostname) {
                    var hostparts = this.hostname.split(/\./);
                    for (var i = 0, l = hostparts.length; i < l; i++) {
                        var part = hostparts[i];
                        if (!part) continue;
                        if (!part.match(hostnamePartPattern)) {
                            var newpart = '';
                            for (var j = 0, k = part.length; j < k; j++) {
                                if (part.charCodeAt(j) > 127) {
                                    // we replace non-ASCII char with a temporary placeholder
                                    // we need this to make sure size of hostname is not
                                    // broken by replacing non-ASCII by nothing
                                    newpart += 'x';
                                } else {
                                    newpart += part[j];
                                }
                            }
                            // we test again with ASCII char only
                            if (!newpart.match(hostnamePartPattern)) {
                                var validParts = hostparts.slice(0, i);
                                var notHost = hostparts.slice(i + 1);
                                var bit = part.match(hostnamePartStart);
                                if (bit) {
                                    validParts.push(bit[1]);
                                    notHost.unshift(bit[2]);
                                }
                                if (notHost.length) {
                                    rest = '/' + notHost.join('.') + rest;
                                }
                                this.hostname = validParts.join('.');
                                break;
                            }
                        }
                    }
                }

                if (this.hostname.length > hostnameMaxLen) {
                    this.hostname = '';
                } else {
                    // hostnames are always lower case.
                    this.hostname = this.hostname.toLowerCase();
                }

                if (!ipv6Hostname) {
                    // IDNA Support: Returns a punycoded representation of "domain".
                    // It only converts parts of the domain name that
                    // have non-ASCII characters, i.e. it doesn't matter if
                    // you call it with a domain that already is ASCII-only.
                    this.hostname = punycode.toASCII(this.hostname);
                }

                var p = this.port ? ':' + this.port : '';
                var h = this.hostname || '';
                this.host = h + p;
                this.href += this.host;

                // strip [ and ] from the hostname
                // the host field still retains them, though
                if (ipv6Hostname) {
                    this.hostname = this.hostname.substr(1, this.hostname.length - 2);
                    if (rest[0] !== '/') {
                        rest = '/' + rest;
                    }
                }
            }

            // now rest is set to the post-host stuff.
            // chop off any delim chars.
            if (!unsafeProtocol[lowerProto]) {

                // First, make 100% sure that any "autoEscape" chars get
                // escaped, even if encodeURIComponent doesn't think they
                // need to be.
                for (var i = 0, l = autoEscape.length; i < l; i++) {
                    var ae = autoEscape[i];
                    if (rest.indexOf(ae) === -1)
                        continue;
                    var esc = encodeURIComponent(ae);
                    if (esc === ae) {
                        esc = escape(ae);
                    }
                    rest = rest.split(ae).join(esc);
                }
            }


            // chop off from the tail first.
            var hash = rest.indexOf('#');
            if (hash !== -1) {
                // got a fragment string.
                this.hash = rest.substr(hash);
                rest = rest.slice(0, hash);
            }
            var qm = rest.indexOf('?');
            if (qm !== -1) {
                this.search = rest.substr(qm);
                this.query = rest.substr(qm + 1);
                if (parseQueryString) {
                    this.query = querystring.parse(this.query);
                }
                rest = rest.slice(0, qm);
            } else if (parseQueryString) {
                // no query string, but parseQueryString still requested
                this.search = '';
                this.query = {};
            }
            if (rest) this.pathname = rest;
            if (slashedProtocol[lowerProto] &&
                this.hostname && !this.pathname) {
                this.pathname = '/';
            }

            //to support http.request
            if (this.pathname || this.search) {
                var p = this.pathname || '';
                var s = this.search || '';
                this.path = p + s;
            }

            // finally, reconstruct the href based on what has been validated.
            this.href = this.format();
            return this;
        };

        // format a parsed object into a url string
        function urlFormat(obj) {
            // ensure it's an object, and not a string url.
            // If it's an obj, this is a no-op.
            // this way, you can call url_format() on strings
            // to clean up potentially wonky urls.
            if (util.isString(obj)) obj = urlParse(obj);
            if (!(obj instanceof Url)) return Url.prototype.format.call(obj);
            return obj.format();
        }

        Url.prototype.format = function() {
            var auth = this.auth || '';
            if (auth) {
                auth = encodeURIComponent(auth);
                auth = auth.replace(/%3A/i, ':');
                auth += '@';
            }

            var protocol = this.protocol || '',
                pathname = this.pathname || '',
                hash = this.hash || '',
                host = false,
                query = '';

            if (this.host) {
                host = auth + this.host;
            } else if (this.hostname) {
                host = auth + (this.hostname.indexOf(':') === -1 ?
                    this.hostname :
                    '[' + this.hostname + ']');
                if (this.port) {
                    host += ':' + this.port;
                }
            }

            if (this.query &&
                util.isObject(this.query) &&
                Object.keys(this.query).length) {
                query = querystring.stringify(this.query);
            }

            var search = this.search || (query && ('?' + query)) || '';

            if (protocol && protocol.substr(-1) !== ':') protocol += ':';

            // only the slashedProtocols get the //.  Not mailto:, xmpp:, etc.
            // unless they had them to begin with.
            if (this.slashes ||
                (!protocol || slashedProtocol[protocol]) && host !== false) {
                host = '//' + (host || '');
                if (pathname && pathname.charAt(0) !== '/') pathname = '/' + pathname;
            } else if (!host) {
                host = '';
            }

            if (hash && hash.charAt(0) !== '#') hash = '#' + hash;
            if (search && search.charAt(0) !== '?') search = '?' + search;

            pathname = pathname.replace(/[?#]/g, function(match) {
                return encodeURIComponent(match);
            });
            search = search.replace('#', '%23');

            return protocol + host + pathname + search + hash;
        };

        function urlResolve(source, relative) {
            return urlParse(source, false, true).resolve(relative);
        }

        Url.prototype.resolve = function(relative) {
            return this.resolveObject(urlParse(relative, false, true)).format();
        };

        function urlResolveObject(source, relative) {
            if (!source) return relative;
            return urlParse(source, false, true).resolveObject(relative);
        }

        Url.prototype.resolveObject = function(relative) {
            if (util.isString(relative)) {
                var rel = new Url();
                rel.parse(relative, false, true);
                relative = rel;
            }

            var result = new Url();
            var tkeys = Object.keys(this);
            for (var tk = 0; tk < tkeys.length; tk++) {
                var tkey = tkeys[tk];
                result[tkey] = this[tkey];
            }

            // hash is always overridden, no matter what.
            // even href="" will remove it.
            result.hash = relative.hash;

            // if the relative url is empty, then there's nothing left to do here.
            if (relative.href === '') {
                result.href = result.format();
                return result;
            }

            // hrefs like //foo/bar always cut to the protocol.
            if (relative.slashes && !relative.protocol) {
                // take everything except the protocol from relative
                var rkeys = Object.keys(relative);
                for (var rk = 0; rk < rkeys.length; rk++) {
                    var rkey = rkeys[rk];
                    if (rkey !== 'protocol')
                        result[rkey] = relative[rkey];
                }

                //urlParse appends trailing / to urls like http://www.example.com
                if (slashedProtocol[result.protocol] &&
                    result.hostname && !result.pathname) {
                    result.path = result.pathname = '/';
                }

                result.href = result.format();
                return result;
            }

            if (relative.protocol && relative.protocol !== result.protocol) {
                // if it's a known url protocol, then changing
                // the protocol does weird things
                // first, if it's not file:, then we MUST have a host,
                // and if there was a path
                // to begin with, then we MUST have a path.
                // if it is file:, then the host is dropped,
                // because that's known to be hostless.
                // anything else is assumed to be absolute.
                if (!slashedProtocol[relative.protocol]) {
                    var keys = Object.keys(relative);
                    for (var v = 0; v < keys.length; v++) {
                        var k = keys[v];
                        result[k] = relative[k];
                    }
                    result.href = result.format();
                    return result;
                }

                result.protocol = relative.protocol;
                if (!relative.host && !hostlessProtocol[relative.protocol]) {
                    var relPath = (relative.pathname || '').split('/');
                    while (relPath.length && !(relative.host = relPath.shift()));
                    if (!relative.host) relative.host = '';
                    if (!relative.hostname) relative.hostname = '';
                    if (relPath[0] !== '') relPath.unshift('');
                    if (relPath.length < 2) relPath.unshift('');
                    result.pathname = relPath.join('/');
                } else {
                    result.pathname = relative.pathname;
                }
                result.search = relative.search;
                result.query = relative.query;
                result.host = relative.host || '';
                result.auth = relative.auth;
                result.hostname = relative.hostname || relative.host;
                result.port = relative.port;
                // to support http.request
                if (result.pathname || result.search) {
                    var p = result.pathname || '';
                    var s = result.search || '';
                    result.path = p + s;
                }
                result.slashes = result.slashes || relative.slashes;
                result.href = result.format();
                return result;
            }

            var isSourceAbs = (result.pathname && result.pathname.charAt(0) === '/'),
                isRelAbs = (
                    relative.host ||
                    relative.pathname && relative.pathname.charAt(0) === '/'
                ),
                mustEndAbs = (isRelAbs || isSourceAbs ||
                    (result.host && relative.pathname)),
                removeAllDots = mustEndAbs,
                srcPath = result.pathname && result.pathname.split('/') || [],
                relPath = relative.pathname && relative.pathname.split('/') || [],
                psychotic = result.protocol && !slashedProtocol[result.protocol];

            // if the url is a non-slashed url, then relative
            // links like ../.. should be able
            // to crawl up to the hostname, as well.  This is strange.
            // result.protocol has already been set by now.
            // Later on, put the first path part into the host field.
            if (psychotic) {
                result.hostname = '';
                result.port = null;
                if (result.host) {
                    if (srcPath[0] === '') srcPath[0] = result.host;
                    else srcPath.unshift(result.host);
                }
                result.host = '';
                if (relative.protocol) {
                    relative.hostname = null;
                    relative.port = null;
                    if (relative.host) {
                        if (relPath[0] === '') relPath[0] = relative.host;
                        else relPath.unshift(relative.host);
                    }
                    relative.host = null;
                }
                mustEndAbs = mustEndAbs && (relPath[0] === '' || srcPath[0] === '');
            }

            if (isRelAbs) {
                // it's absolute.
                result.host = (relative.host || relative.host === '') ?
                    relative.host : result.host;
                result.hostname = (relative.hostname || relative.hostname === '') ?
                    relative.hostname : result.hostname;
                result.search = relative.search;
                result.query = relative.query;
                srcPath = relPath;
                // fall through to the dot-handling below.
            } else if (relPath.length) {
                // it's relative
                // throw away the existing file, and take the new path instead.
                if (!srcPath) srcPath = [];
                srcPath.pop();
                srcPath = srcPath.concat(relPath);
                result.search = relative.search;
                result.query = relative.query;
            } else if (!util.isNullOrUndefined(relative.search)) {
                // just pull out the search.
                // like href='?foo'.
                // Put this after the other two cases because it simplifies the booleans
                if (psychotic) {
                    result.hostname = result.host = srcPath.shift();
                    //occationaly the auth can get stuck only in host
                    //this especially happens in cases like
                    //url.resolveObject('mailto:local1@domain1', 'local2@domain2')
                    var authInHost = result.host && result.host.indexOf('@') > 0 ?
                        result.host.split('@') : false;
                    if (authInHost) {
                        result.auth = authInHost.shift();
                        result.host = result.hostname = authInHost.shift();
                    }
                }
                result.search = relative.search;
                result.query = relative.query;
                //to support http.request
                if (!util.isNull(result.pathname) || !util.isNull(result.search)) {
                    result.path = (result.pathname ? result.pathname : '') +
                        (result.search ? result.search : '');
                }
                result.href = result.format();
                return result;
            }

            if (!srcPath.length) {
                // no path at all.  easy.
                // we've already handled the other stuff above.
                result.pathname = null;
                //to support http.request
                if (result.search) {
                    result.path = '/' + result.search;
                } else {
                    result.path = null;
                }
                result.href = result.format();
                return result;
            }

            // if a url ENDs in . or .., then it must get a trailing slash.
            // however, if it ends in anything else non-slashy,
            // then it must NOT get a trailing slash.
            var last = srcPath.slice(-1)[0];
            var hasTrailingSlash = (
                (result.host || relative.host || srcPath.length > 1) &&
                (last === '.' || last === '..') || last === '');

            // strip single dots, resolve double dots to parent dir
            // if the path tries to go above the root, `up` ends up > 0
            var up = 0;
            for (var i = srcPath.length; i >= 0; i--) {
                last = srcPath[i];
                if (last === '.') {
                    srcPath.splice(i, 1);
                } else if (last === '..') {
                    srcPath.splice(i, 1);
                    up++;
                } else if (up) {
                    srcPath.splice(i, 1);
                    up--;
                }
            }

            // if the path is allowed to go above the root, restore leading ..s
            if (!mustEndAbs && !removeAllDots) {
                for (; up--; up) {
                    srcPath.unshift('..');
                }
            }

            if (mustEndAbs && srcPath[0] !== '' &&
                (!srcPath[0] || srcPath[0].charAt(0) !== '/')) {
                srcPath.unshift('');
            }

            if (hasTrailingSlash && (srcPath.join('/').substr(-1) !== '/')) {
                srcPath.push('');
            }

            var isAbsolute = srcPath[0] === '' ||
                (srcPath[0] && srcPath[0].charAt(0) === '/');

            // put the host back
            if (psychotic) {
                result.hostname = result.host = isAbsolute ? '' :
                    srcPath.length ? srcPath.shift() : '';
                //occationaly the auth can get stuck only in host
                //this especially happens in cases like
                //url.resolveObject('mailto:local1@domain1', 'local2@domain2')
                var authInHost = result.host && result.host.indexOf('@') > 0 ?
                    result.host.split('@') : false;
                if (authInHost) {
                    result.auth = authInHost.shift();
                    result.host = result.hostname = authInHost.shift();
                }
            }

            mustEndAbs = mustEndAbs || (result.host && srcPath.length);

            if (mustEndAbs && !isAbsolute) {
                srcPath.unshift('');
            }

            if (!srcPath.length) {
                result.pathname = null;
                result.path = null;
            } else {
                result.pathname = srcPath.join('/');
            }

            //to support request.http
            if (!util.isNull(result.pathname) || !util.isNull(result.search)) {
                result.path = (result.pathname ? result.pathname : '') +
                    (result.search ? result.search : '');
            }
            result.auth = relative.auth || result.auth;
            result.slashes = result.slashes || relative.slashes;
            result.href = result.format();
            return result;
        };

        Url.prototype.parseHost = function() {
            var host = this.host;
            var port = portPattern.exec(host);
            if (port) {
                port = port[0];
                if (port !== ':') {
                    this.port = port.substr(1);
                }
                host = host.substr(0, host.length - port.length);
            }
            if (host) this.hostname = host;
        };

    }, {
        "./util": 52,
        "punycode": 10,
        "querystring": 13
    }],
    52: [function(require, module, exports) {
        'use strict';

        module.exports = {
            isString: function(arg) {
                return typeof(arg) === 'string';
            },
            isObject: function(arg) {
                return typeof(arg) === 'object' && arg !== null;
            },
            isNull: function(arg) {
                return arg === null;
            },
            isNullOrUndefined: function(arg) {
                return arg == null;
            }
        };

    }, {}],
    53: [function(require, module, exports) {
        (function(global) {
            (function() {

                /**
                 * Module exports.
                 */

                module.exports = deprecate;

                /**
                 * Mark that a method should not be used.
                 * Returns a modified function which warns once by default.
                 *
                 * If `localStorage.noDeprecation = true` is set, then it is a no-op.
                 *
                 * If `localStorage.throwDeprecation = true` is set, then deprecated functions
                 * will throw an Error when invoked.
                 *
                 * If `localStorage.traceDeprecation = true` is set, then deprecated functions
                 * will invoke `console.trace()` instead of `console.error()`.
                 *
                 * @param {Function} fn - the function to deprecate
                 * @param {String} msg - the string to print to the console when `fn` is invoked
                 * @returns {Function} a new "deprecated" version of `fn`
                 * @api public
                 */

                function deprecate(fn, msg) {
                    if (config('noDeprecation')) {
                        return fn;
                    }

                    var warned = false;

                    function deprecated() {
                        if (!warned) {
                            if (config('throwDeprecation')) {
                                throw new Error(msg);
                            } else if (config('traceDeprecation')) {
                                console.trace(msg);
                            } else {
                                console.warn(msg);
                            }
                            warned = true;
                        }
                        return fn.apply(this, arguments);
                    }

                    return deprecated;
                }

                /**
                 * Checks `localStorage` for boolean values for the given `name`.
                 *
                 * @param {String} name
                 * @returns {Boolean}
                 * @api private
                 */

                function config(name) {
                    // accessing global.localStorage can trigger a DOMException in sandboxed iframes
                    try {
                        if (!global.localStorage) return false;
                    } catch (_) {
                        return false;
                    }
                    var val = global.localStorage[name];
                    if (null == val) return false;
                    return String(val).toLowerCase() === 'true';
                }

            }).call(this)
        }).call(this, typeof global !== "undefined" ? global : typeof self !== "undefined" ? self : typeof window !== "undefined" ? window : {})
    }, {}],
    54: [function(require, module, exports) {
        var indexOf = function(xs, item) {
            if (xs.indexOf) return xs.indexOf(item);
            else
                for (var i = 0; i < xs.length; i++) {
                    if (xs[i] === item) return i;
                }
            return -1;
        };
        var Object_keys = function(obj) {
            if (Object.keys) return Object.keys(obj)
            else {
                var res = [];
                for (var key in obj) res.push(key)
                return res;
            }
        };

        var forEach = function(xs, fn) {
            if (xs.forEach) return xs.forEach(fn)
            else
                for (var i = 0; i < xs.length; i++) {
                    fn(xs[i], i, xs);
                }
        };

        var defineProp = (function() {
            try {
                Object.defineProperty({}, '_', {});
                return function(obj, name, value) {
                    Object.defineProperty(obj, name, {
                        writable: true,
                        enumerable: false,
                        configurable: true,
                        value: value
                    })
                };
            } catch (e) {
                return function(obj, name, value) {
                    obj[name] = value;
                };
            }
        }());

        var globals = ['Array', 'Boolean', 'Date', 'Error', 'EvalError', 'Function',
            'Infinity', 'JSON', 'Math', 'NaN', 'Number', 'Object', 'RangeError',
            'ReferenceError', 'RegExp', 'String', 'SyntaxError', 'TypeError', 'URIError',
            'decodeURI', 'decodeURIComponent', 'encodeURI', 'encodeURIComponent', 'escape',
            'eval', 'isFinite', 'isNaN', 'parseFloat', 'parseInt', 'undefined', 'unescape'
        ];

        function Context() {}
        Context.prototype = {};

        var Script = exports.Script = function NodeScript(code) {
            if (!(this instanceof Script)) return new Script(code);
            this.code = code;
        };

        Script.prototype.runInContext = function(context) {
            if (!(context instanceof Context)) {
                throw new TypeError("needs a 'context' argument.");
            }

            var iframe = document.createElement('iframe');
            if (!iframe.style) iframe.style = {};
            iframe.style.display = 'none';

            document.body.appendChild(iframe);

            var win = iframe.contentWindow;
            var wEval = win.eval,
                wExecScript = win.execScript;

            if (!wEval && wExecScript) {
                // win.eval() magically appears when this is called in IE:
                wExecScript.call(win, 'null');
                wEval = win.eval;
            }

            forEach(Object_keys(context), function(key) {
                win[key] = context[key];
            });
            forEach(globals, function(key) {
                if (context[key]) {
                    win[key] = context[key];
                }
            });

            var winKeys = Object_keys(win);

            var res = wEval.call(win, this.code);

            forEach(Object_keys(win), function(key) {
                // Avoid copying circular objects like `top` and `window` by only
                // updating existing context properties or new properties in the `win`
                // that was only introduced after the eval.
                if (key in context || indexOf(winKeys, key) === -1) {
                    context[key] = win[key];
                }
            });

            forEach(globals, function(key) {
                if (!(key in context)) {
                    defineProp(context, key, win[key]);
                }
            });

            document.body.removeChild(iframe);

            return res;
        };

        Script.prototype.runInThisContext = function() {
            return eval(this.code); // maybe...
        };

        Script.prototype.runInNewContext = function(context) {
            var ctx = Script.createContext(context);
            var res = this.runInContext(ctx);

            if (context) {
                forEach(Object_keys(ctx), function(key) {
                    context[key] = ctx[key];
                });
            }

            return res;
        };

        forEach(Object_keys(Script.prototype), function(name) {
            exports[name] = Script[name] = function(code) {
                var s = Script(code);
                return s[name].apply(s, [].slice.call(arguments, 1));
            };
        });

        exports.isContext = function(context) {
            return context instanceof Context;
        };

        exports.createScript = function(code) {
            return exports.Script(code);
        };

        exports.createContext = Script.createContext = function(context) {
            var copy = new Context();
            if (typeof context === 'object') {
                forEach(Object_keys(context), function(key) {
                    copy[key] = context[key];
                });
            }
            return copy;
        };

    }, {}],
    55: [function(require, module, exports) {
        module.exports = extend

        var hasOwnProperty = Object.prototype.hasOwnProperty;

        function extend() {
            var target = {}

            for (var i = 0; i < arguments.length; i++) {
                var source = arguments[i]

                for (var key in source) {
                    if (hasOwnProperty.call(source, key)) {
                        target[key] = source[key]
                    }
                }
            }

            return target
        }

    }, {}],
    56: [function(require, module, exports) {
        var ytdl = require('ytdl-core');
        Exported.ytdl = ytdl;

        module.exports = ytdl;

    }, {
        "ytdl-core": 67
    }],
    57: [function(require, module, exports) {
        "use strict";
        var __importDefault = (this && this.__importDefault) || function(mod) {
            return (mod && mod.__esModule) ? mod : {
                "default": mod
            };
        };
        Object.defineProperty(exports, "__esModule", {
            value: true
        });
        const stream_1 = require("stream");
        const sax_1 = __importDefault(require("sax"));
        const parse_time_1 = require("./parse-time");
        /**
         * A wrapper around sax that emits segments.
         */
        class DashMPDParser extends stream_1.Writable {
            constructor(targetID) {
                super();
                this._parser = sax_1.default.createStream(false, {
                    lowercase: true
                });
                this._parser.on('error', this.destroy.bind(this));
                let lastTag;
                let currtime = 0;
                let seq = 0;
                let segmentTemplate;
                let timescale, offset, duration, baseURL;
                let timeline = [];
                let getSegments = false;
                let gotSegments = false;
                let isStatic;
                let treeLevel;
                let periodStart;
                const tmpl = (str) => {
                    const context = {
                        RepresentationID: targetID,
                        Number: seq,
                        Time: currtime,
                    };
                    return str.replace(/\$(\w+)\$/g, (m, p1) => `${context[p1]}`);
                };
                this._parser.on('opentag', node => {
                    switch (node.name) {
                        case 'mpd':
                            currtime =
                                node.attributes.availabilitystarttime ?
                                new Date(node.attributes.availabilitystarttime).getTime() : 0;
                            isStatic = node.attributes.type !== 'dynamic';
                            break;
                        case 'period':
                            // Reset everything on <Period> tag.
                            seq = 0;
                            timescale = 1000;
                            duration = 0;
                            offset = 0;
                            baseURL = [];
                            treeLevel = 0;
                            periodStart = parse_time_1.durationStr(node.attributes.start) || 0;
                            break;
                        case 'segmentlist':
                            seq = parseInt(node.attributes.startnumber) || seq;
                            timescale = parseInt(node.attributes.timescale) || timescale;
                            duration = parseInt(node.attributes.duration) || duration;
                            offset = parseInt(node.attributes.presentationtimeoffset) || offset;
                            break;
                        case 'segmenttemplate':
                            segmentTemplate = node.attributes;
                            seq = parseInt(node.attributes.startnumber) || seq;
                            timescale = parseInt(node.attributes.timescale) || timescale;
                            break;
                        case 'segmenttimeline':
                        case 'baseurl':
                            lastTag = node.name;
                            break;
                        case 's':
                            timeline.push({
                                duration: parseInt(node.attributes.d),
                                repeat: parseInt(node.attributes.r),
                                time: parseInt(node.attributes.t),
                            });
                            break;
                        case 'adaptationset':
                        case 'representation':
                            treeLevel++;
                            if (!targetID) {
                                targetID = node.attributes.id;
                            }
                            getSegments = node.attributes.id === `${targetID}`;
                            if (getSegments) {
                                if (periodStart) {
                                    currtime += periodStart;
                                }
                                if (offset) {
                                    currtime -= offset / timescale * 1000;
                                }
                                this.emit('starttime', currtime);
                            }
                            break;
                        case 'initialization':
                            if (getSegments) {
                                this.emit('item', {
                                    url: baseURL.filter(s => !!s).join('') + node.attributes.sourceurl,
                                    seq: seq,
                                    init: true,
                                    duration: 0,
                                });
                            }
                            break;
                        case 'segmenturl':
                            if (getSegments) {
                                gotSegments = true;
                                let tl = timeline.shift();
                                let segmentDuration = ((tl === null || tl === void 0 ? void 0 : tl.duration) || duration) / timescale * 1000;
                                this.emit('item', {
                                    url: baseURL.filter(s => !!s).join('') + node.attributes.media,
                                    seq: seq++,
                                    duration: segmentDuration,
                                });
                                currtime += segmentDuration;
                            }
                            break;
                    }
                });
                const onEnd = () => {
                    if (isStatic) {
                        this.emit('endlist');
                    }
                    if (!getSegments) {
                        this.destroy(Error(`Representation '${targetID}' not found`));
                    } else {
                        this.emit('end');
                    }
                };
                this._parser.on('closetag', tagName => {
                    switch (tagName) {
                        case 'adaptationset':
                        case 'representation':
                            treeLevel--;
                            if (segmentTemplate && timeline.length) {
                                gotSegments = true;
                                if (segmentTemplate.initialization) {
                                    this.emit('item', {
                                        url: baseURL.filter(s => !!s).join('') +
                                            tmpl(segmentTemplate.initialization),
                                        seq: seq,
                                        init: true,
                                        duration: 0,
                                    });
                                }
                                for (let {
                                        duration: itemDuration,
                                        repeat,
                                        time
                                    }
                                    of timeline) {
                                    itemDuration = itemDuration / timescale * 1000;
                                    repeat = repeat || 1;
                                    currtime = time || currtime;
                                    for (let i = 0; i < repeat; i++) {
                                        this.emit('item', {
                                            url: baseURL.filter(s => !!s).join('') +
                                                tmpl(segmentTemplate.media),
                                            seq: seq++,
                                            duration: itemDuration,
                                        });
                                        currtime += itemDuration;
                                    }
                                }
                            }
                            if (gotSegments) {
                                this.emit('endearly');
                                onEnd();
                                this._parser.removeAllListeners();
                                this.removeAllListeners('finish');
                            }
                            break;
                    }
                });
                this._parser.on('text', text => {
                    if (lastTag === 'baseurl') {
                        baseURL[treeLevel] = text;
                        lastTag = null;
                    }
                });
                this.on('finish', onEnd);
            }
            _write(chunk, encoding, callback) {
                this._parser.write(chunk);
                callback();
            }
        }
        exports.default = DashMPDParser;

    }, {
        "./parse-time": 60,
        "sax": 63,
        "stream": 15
    }],
    58: [function(require, module, exports) {
        "use strict";
        var __importDefault = (this && this.__importDefault) || function(mod) {
            return (mod && mod.__esModule) ? mod : {
                "default": mod
            };
        };
        const stream_1 = require("stream");
        const miniget_1 = __importDefault(require("miniget"));
        const m3u8_parser_1 = __importDefault(require("./m3u8-parser"));
        const dash_mpd_parser_1 = __importDefault(require("./dash-mpd-parser"));
        const queue_1 = require("./queue");
        const parse_time_1 = require("./parse-time");
        const supportedParsers = {
            m3u8: m3u8_parser_1.default,
            'dash-mpd': dash_mpd_parser_1.default,
        };
        let m3u8stream = ((playlistURL, options = {}) => {
            const stream = new stream_1.PassThrough({
                highWaterMark: options.highWaterMark
            });
            const chunkReadahead = options.chunkReadahead || 3;
            // 20 seconds.
            const liveBuffer = options.liveBuffer || 20000;
            const requestOptions = options.requestOptions;
            const Parser = supportedParsers[options.parser || (/\.mpd$/.test(playlistURL) ? 'dash-mpd' : 'm3u8')];
            if (!Parser) {
                throw TypeError(`parser '${options.parser}' not supported`);
            }
            let begin = 0;
            if (typeof options.begin !== 'undefined') {
                begin = typeof options.begin === 'string' ?
                    parse_time_1.humanStr(options.begin) :
                    Math.max(options.begin - liveBuffer, 0);
            }
            const forwardEvents = (req) => {
                for (let event of ['abort', 'request', 'response', 'redirect', 'retry', 'reconnect']) {
                    req.on(event, stream.emit.bind(stream, event));
                }
            };
            let currSegment;
            const streamQueue = new queue_1.Queue((req, callback) => {
                currSegment = req;
                // Count the size manually, since the `content-length` header is not
                // always there.
                let size = 0;
                req.on('data', (chunk) => size += chunk.length);
                req.pipe(stream, {
                    end: false
                });
                req.on('end', () => callback(null, size));
            }, {
                concurrency: 1
            });
            let segmentNumber = 0;
            let downloaded = 0;
            const requestQueue = new queue_1.Queue((segment, callback) => {
                let reqOptions = Object.assign({}, requestOptions);
                if (segment.range) {
                    reqOptions.headers = Object.assign({}, reqOptions.headers, {
                        Range: `bytes=${segment.range.start}-${segment.range.end}`,
                    });
                }
                let req = miniget_1.default(new URL(segment.url, playlistURL).toString(), reqOptions);
                req.on('error', callback);
                forwardEvents(req);
                streamQueue.push(req, (_, size) => {
                    downloaded += +size;
                    stream.emit('progress', {
                        num: ++segmentNumber,
                        size: size,
                        duration: segment.duration,
                        url: segment.url,
                    }, requestQueue.total, downloaded);
                    callback(null);
                });
            }, {
                concurrency: chunkReadahead
            });
            const onError = (err) => {
                stream.emit('error', err);
                // Stop on any error.
                stream.end();
            };
            // When to look for items again.
            let refreshThreshold;
            let minRefreshTime;
            let refreshTimeout;
            let fetchingPlaylist = true;
            let ended = false;
            let isStatic = false;
            let lastRefresh;
            const onQueuedEnd = (err) => {
                currSegment = null;
                if (err) {
                    onError(err);
                } else if (!fetchingPlaylist && !ended && !isStatic &&
                    requestQueue.tasks.length + requestQueue.active <= refreshThreshold) {
                    let ms = Math.max(0, minRefreshTime - (Date.now() - lastRefresh));
                    fetchingPlaylist = true;
                    refreshTimeout = setTimeout(refreshPlaylist, ms);
                } else if ((ended || isStatic) &&
                    !requestQueue.tasks.length && !requestQueue.active) {
                    stream.end();
                }
            };
            let currPlaylist;
            let lastSeq;
            let starttime = 0;
            const refreshPlaylist = () => {
                lastRefresh = Date.now();
                currPlaylist = miniget_1.default(playlistURL, requestOptions);
                currPlaylist.on('error', onError);
                forwardEvents(currPlaylist);
                const parser = currPlaylist.pipe(new Parser(options.id));
                parser.on('starttime', (a) => {
                    if (starttime) {
                        return;
                    }
                    starttime = a;
                    if (typeof options.begin === 'string' && begin >= 0) {
                        begin += starttime;
                    }
                });
                parser.on('endlist', () => {
                    isStatic = true;
                });
                parser.on('endearly', currPlaylist.unpipe.bind(currPlaylist, parser));
                let addedItems = [];
                const addItem = (item) => {
                    if (!item.init) {
                        if (item.seq <= lastSeq) {
                            return;
                        }
                        lastSeq = item.seq;
                    }
                    begin = item.time;
                    requestQueue.push(item, onQueuedEnd);
                    addedItems.push(item);
                };
                let tailedItems = [],
                    tailedItemsDuration = 0;
                parser.on('item', (item) => {
                    let timedItem = Object.assign({
                        time: starttime
                    }, item);
                    if (begin <= timedItem.time) {
                        addItem(timedItem);
                    } else {
                        tailedItems.push(timedItem);
                        tailedItemsDuration += timedItem.duration;
                        // Only keep the last `liveBuffer` of items.
                        while (tailedItems.length > 1 &&
                            tailedItemsDuration - tailedItems[0].duration > liveBuffer) {
                            const lastItem = tailedItems.shift();
                            tailedItemsDuration -= lastItem.duration;
                        }
                    }
                    starttime += timedItem.duration;
                });
                parser.on('end', () => {
                    currPlaylist = null;
                    // If we are too ahead of the stream, make sure to get the
                    // latest available items with a small buffer.
                    if (!addedItems.length && tailedItems.length) {
                        tailedItems.forEach(item => {
                            addItem(item);
                        });
                    }
                    // Refresh the playlist when remaining segments get low.
                    refreshThreshold = Math.max(1, Math.ceil(addedItems.length * 0.01));
                    // Throttle refreshing the playlist by looking at the duration
                    // of live items added on this refresh.
                    minRefreshTime =
                        addedItems.reduce((total, item) => item.duration + total, 0);
                    fetchingPlaylist = false;
                    onQueuedEnd(null);
                });
            };
            refreshPlaylist();
            stream.end = () => {
                ended = true;
                streamQueue.die();
                requestQueue.die();
                clearTimeout(refreshTimeout);
                currPlaylist === null || currPlaylist === void 0 ? void 0 : currPlaylist.destroy();
                currSegment === null || currSegment === void 0 ? void 0 : currSegment.destroy();
                stream_1.PassThrough.prototype.end.call(stream, null);
                return stream;
            };
            return stream;
        });
        m3u8stream.parseTimestamp = parse_time_1.humanStr;
        module.exports = m3u8stream;

    }, {
        "./dash-mpd-parser": 57,
        "./m3u8-parser": 59,
        "./parse-time": 60,
        "./queue": 61,
        "miniget": 62,
        "stream": 15
    }],
    59: [function(require, module, exports) {
        "use strict";
        Object.defineProperty(exports, "__esModule", {
            value: true
        });
        const stream_1 = require("stream");
        /**
         * A very simple m3u8 playlist file parser that detects tags and segments.
         */
        class m3u8Parser extends stream_1.Writable {
            constructor() {
                super();
                this._lastLine = '';
                this._seq = 0;
                this._nextItemDuration = null;
                this._nextItemRange = null;
                this._lastItemRangeEnd = 0;
                this.on('finish', () => {
                    this._parseLine(this._lastLine);
                    this.emit('end');
                });
            }
            _parseAttrList(value) {
                let attrs = {};
                let regex = /([A-Z0-9-]+)=(?:"([^"]*?)"|([^,]*?))/g;
                let match;
                while ((match = regex.exec(value)) !== null) {
                    attrs[match[1]] = match[2] || match[3];
                }
                return attrs;
            }
            _parseRange(value) {
                if (!value)
                    return null;
                let svalue = value.split('@');
                let start = svalue[1] ? parseInt(svalue[1]) : this._lastItemRangeEnd + 1;
                let end = start + parseInt(svalue[0]) - 1;
                let range = {
                    start,
                    end
                };
                this._lastItemRangeEnd = range.end;
                return range;
            }
            _parseLine(line) {
                let match = line.match(/^#(EXT[A-Z0-9-]+)(?::(.*))?/);
                if (match) {
                    // This is a tag.
                    const tag = match[1];
                    const value = match[2] || '';
                    switch (tag) {
                        case 'EXT-X-PROGRAM-DATE-TIME':
                            this.emit('starttime', new Date(value).getTime());
                            break;
                        case 'EXT-X-MEDIA-SEQUENCE':
                            this._seq = parseInt(value);
                            break;
                        case 'EXT-X-MAP': {
                            let attrs = this._parseAttrList(value);
                            if (!attrs.URI) {
                                this.destroy(new Error('`EXT-X-MAP` found without required attribute `URI`'));
                                return;
                            }
                            this.emit('item', {
                                url: attrs.URI,
                                seq: this._seq,
                                init: true,
                                duration: 0,
                                range: this._parseRange(attrs.BYTERANGE),
                            });
                            break;
                        }
                        case 'EXT-X-BYTERANGE': {
                            this._nextItemRange = this._parseRange(value);
                            break;
                        }
                        case 'EXTINF':
                            this._nextItemDuration =
                                Math.round(parseFloat(value.split(',')[0]) * 1000);
                            break;
                        case 'EXT-X-ENDLIST':
                            this.emit('endlist');
                            break;
                    }
                } else if (!/^#/.test(line) && line.trim()) {
                    // This is a segment
                    this.emit('item', {
                        url: line.trim(),
                        seq: this._seq++,
                        duration: this._nextItemDuration,
                        range: this._nextItemRange,
                    });
                    this._nextItemRange = null;
                }
            }
            _write(chunk, encoding, callback) {
                let lines = chunk.toString('utf8').split('\n');
                if (this._lastLine) {
                    lines[0] = this._lastLine + lines[0];
                }
                lines.forEach((line, i) => {
                    if (this.destroyed)
                        return;
                    if (i < lines.length - 1) {
                        this._parseLine(line);
                    } else {
                        // Save the last line in case it has been broken up.
                        this._lastLine = line;
                    }
                });
                callback();
            }
        }
        exports.default = m3u8Parser;

    }, {
        "stream": 15
    }],
    60: [function(require, module, exports) {
        "use strict";
        Object.defineProperty(exports, "__esModule", {
            value: true
        });
        exports.durationStr = exports.humanStr = void 0;
        const numberFormat = /^\d+$/;
        const timeFormat = /^(?:(?:(\d+):)?(\d{1,2}):)?(\d{1,2})(?:\.(\d{3}))?$/;
        const timeUnits = {
            ms: 1,
            s: 1000,
            m: 60000,
            h: 3600000,
        };
        /**
         * Converts human friendly time to milliseconds. Supports the format
         * 00:00:00.000 for hours, minutes, seconds, and milliseconds respectively.
         * And 0ms, 0s, 0m, 0h, and together 1m1s.
         *
         * @param {number|string} time
         * @returns {number}
         */
        exports.humanStr = (time) => {
            if (typeof time === 'number') {
                return time;
            }
            if (numberFormat.test(time)) {
                return +time;
            }
            const firstFormat = timeFormat.exec(time);
            if (firstFormat) {
                return (+(firstFormat[1] || 0) * timeUnits.h) +
                    (+(firstFormat[2] || 0) * timeUnits.m) +
                    (+firstFormat[3] * timeUnits.s) +
                    +(firstFormat[4] || 0);
            } else {
                let total = 0;
                const r = /(-?\d+)(ms|s|m|h)/g;
                let rs;
                while ((rs = r.exec(time)) !== null) {
                    total += +rs[1] * timeUnits[rs[2]];
                }
                return total;
            }
        };
        /**
         * Parses a duration string in the form of "123.456S", returns milliseconds.
         *
         * @param {string} time
         * @returns {number}
         */
        exports.durationStr = (time) => {
            let total = 0;
            const r = /(\d+(?:\.\d+)?)(S|M|H)/g;
            let rs;
            while ((rs = r.exec(time)) !== null) {
                total += +rs[1] * timeUnits[rs[2].toLowerCase()];
            }
            return total;
        };

    }, {}],
    61: [function(require, module, exports) {
        "use strict";
        Object.defineProperty(exports, "__esModule", {
            value: true
        });
        exports.Queue = void 0;
        class Queue {
            /**
             * A really simple queue with concurrency.
             *
             * @param {Function} worker
             * @param {Object} options
             * @param {!number} options.concurrency
             */
            constructor(worker, options = {}) {
                this._worker = worker;
                this._concurrency = options.concurrency || 1;
                this.tasks = [];
                this.total = 0;
                this.active = 0;
            }
            /**
             * Push a task to the queue.
             *
             *  @param {T} item
             *  @param {!Function} callback
             */
            push(item, callback) {
                this.tasks.push({
                    item,
                    callback
                });
                this.total++;
                this._next();
            }
            /**
             * Process next job in queue.
             */
            _next() {
                if (this.active >= this._concurrency || !this.tasks.length) {
                    return;
                }
                const {
                    item,
                    callback
                } = this.tasks.shift();
                let callbackCalled = false;
                this.active++;
                this._worker(item, (err, result) => {
                    if (callbackCalled) {
                        return;
                    }
                    this.active--;
                    callbackCalled = true;
                    callback === null || callback === void 0 ? void 0 : callback(err, result);
                    this._next();
                });
            }
            /**
             * Stops processing queued jobs.
             */
            die() {
                this.tasks = [];
            }
        }
        exports.Queue = Queue;

    }, {}],
    62: [function(require, module, exports) {
        (function(process) {
            (function() {
                "use strict";
                var __importDefault = (this && this.__importDefault) || function(mod) {
                    return (mod && mod.__esModule) ? mod : {
                        "default": mod
                    };
                };
                const http_1 = __importDefault(require("http"));
                const https_1 = __importDefault(require("https"));
                const stream_1 = require("stream");
                const httpLibs = {
                    'http:': http_1.default,
                    'https:': https_1.default
                };
                const redirectStatusCodes = new Set([301, 302, 303, 307, 308]);
                const retryStatusCodes = new Set([429, 503]);
                // `request`, `response`, `abort`, left out, miniget will emit these.
                const requestEvents = ['connect', 'continue', 'information', 'socket', 'timeout', 'upgrade'];
                const responseEvents = ['aborted'];
                Miniget.MinigetError = class MinigetError extends Error {
                    constructor(message, statusCode) {
                        super(message);
                        this.statusCode = statusCode;
                    }
                };
                Miniget.defaultOptions = {
                    maxRedirects: 10,
                    maxRetries: 2,
                    maxReconnects: 0,
                    backoff: {
                        inc: 100,
                        max: 10000
                    },
                };

                function Miniget(url, options = {}) {
                    var _a;
                    const opts = Object.assign({}, Miniget.defaultOptions, options);
                    const stream = new stream_1.PassThrough({
                        highWaterMark: opts.highWaterMark
                    });
                    stream.destroyed = stream.aborted = false;
                    let activeRequest;
                    let activeResponse;
                    let activeDecodedStream;
                    let redirects = 0;
                    let retries = 0;
                    let retryTimeout;
                    let reconnects = 0;
                    let contentLength;
                    let acceptRanges = false;
                    let rangeStart = 0,
                        rangeEnd;
                    let downloaded = 0;
                    // Check if this is a ranged request.
                    if ((_a = opts.headers) === null || _a === void 0 ? void 0 : _a.Range) {
                        let r = /bytes=(\d+)-(\d+)?/.exec(`${opts.headers.Range}`);
                        if (r) {
                            rangeStart = parseInt(r[1], 10);
                            rangeEnd = parseInt(r[2], 10);
                        }
                    }
                    // Add `Accept-Encoding` header.
                    if (opts.acceptEncoding) {
                        opts.headers = Object.assign({
                            'Accept-Encoding': Object.keys(opts.acceptEncoding).join(', '),
                        }, opts.headers);
                    }
                    const downloadHasStarted = () => activeDecodedStream && downloaded > 0;
                    const downloadComplete = () => !acceptRanges || downloaded === contentLength;
                    const reconnect = (err) => {
                        activeDecodedStream = null;
                        retries = 0;
                        let inc = opts.backoff.inc;
                        let ms = Math.min(inc, opts.backoff.max);
                        retryTimeout = setTimeout(doDownload, ms);
                        stream.emit('reconnect', reconnects, err);
                    };
                    const reconnectIfEndedEarly = (err) => {
                        if (options.method !== 'HEAD' && !downloadComplete() && reconnects++ < opts.maxReconnects) {
                            reconnect(err);
                            return true;
                        }
                        return false;
                    };
                    const retryRequest = (retryOptions) => {
                        if (stream.destroyed) {
                            return false;
                        }
                        if (downloadHasStarted()) {
                            return reconnectIfEndedEarly(retryOptions.err);
                        } else if ((!retryOptions.err || retryOptions.err.message === 'ENOTFOUND') &&
                            retries++ < opts.maxRetries) {
                            let ms = retryOptions.retryAfter ||
                                Math.min(retries * opts.backoff.inc, opts.backoff.max);
                            retryTimeout = setTimeout(doDownload, ms);
                            stream.emit('retry', retries, retryOptions.err);
                            return true;
                        }
                        return false;
                    };
                    const forwardEvents = (ee, events) => {
                        for (let event of events) {
                            ee.on(event, stream.emit.bind(stream, event));
                        }
                    };
                    const doDownload = () => {
                        let parsed = {},
                            httpLib;
                        try {
                            let urlObj = typeof url === 'string' ? new URL(url) : url;
                            parsed = Object.assign({}, {
                                host: urlObj.host,
                                hostname: urlObj.hostname,
                                path: urlObj.pathname + urlObj.search + urlObj.hash,
                                port: urlObj.port,
                                protocol: urlObj.protocol,
                            });
                            if (urlObj.username) {
                                parsed.auth = `${urlObj.username}:${urlObj.password}`;
                            }
                            httpLib = httpLibs[String(parsed.protocol)];
                        } catch (err) {
                            // Let the error be caught by the if statement below.
                        }
                        if (!httpLib) {
                            stream.emit('error', new Miniget.MinigetError(`Invalid URL: ${url}`));
                            return;
                        }
                        Object.assign(parsed, opts);
                        if (acceptRanges && downloaded > 0) {
                            let start = downloaded + rangeStart;
                            let end = rangeEnd || '';
                            parsed.headers = Object.assign({}, parsed.headers, {
                                Range: `bytes=${start}-${end}`,
                            });
                        }
                        if (opts.transform) {
                            try {
                                parsed = opts.transform(parsed);
                            } catch (err) {
                                stream.emit('error', err);
                                return;
                            }
                            if (!parsed || parsed.protocol) {
                                httpLib = httpLibs[String(parsed === null || parsed === void 0 ? void 0 : parsed.protocol)];
                                if (!httpLib) {
                                    stream.emit('error', new Miniget.MinigetError('Invalid URL object from `transform` function'));
                                    return;
                                }
                            }
                        }
                        const onError = (err) => {
                            if (stream.destroyed || stream.readableEnded) {
                                return;
                            }
                            cleanup();
                            if (!retryRequest({
                                    err
                                })) {
                                stream.emit('error', err);
                            } else {
                                activeRequest.removeListener('close', onRequestClose);
                            }
                        };
                        const onRequestClose = () => {
                            cleanup();
                            retryRequest({});
                        };
                        const cleanup = () => {
                            activeRequest.removeListener('close', onRequestClose);
                            activeResponse === null || activeResponse === void 0 ? void 0 : activeResponse.removeListener('data', onData);
                            activeDecodedStream === null || activeDecodedStream === void 0 ? void 0 : activeDecodedStream.removeListener('end', onEnd);
                        };
                        const onData = (chunk) => {
                            downloaded += chunk.length;
                        };
                        const onEnd = () => {
                            cleanup();
                            if (!reconnectIfEndedEarly()) {
                                stream.end();
                            }
                        };
                        activeRequest = httpLib.request(parsed, (res) => {
                            // Needed for node v10, v12.
                            // istanbul ignore next
                            if (stream.destroyed) {
                                return;
                            }
                            if (redirectStatusCodes.has(res.statusCode)) {
                                if (redirects++ >= opts.maxRedirects) {
                                    stream.emit('error', new Miniget.MinigetError('Too many redirects'));
                                } else {
                                    if (res.headers.location) {
                                        url = res.headers.location;
                                    } else {
                                        let err = new Miniget.MinigetError('Redirect status code given with no location', res.statusCode);
                                        stream.emit('error', err);
                                        cleanup();
                                        return;
                                    }
                                    setTimeout(doDownload, parseInt(res.headers['retry-after'] || '0', 10) * 1000);
                                    stream.emit('redirect', url);
                                }
                                cleanup();
                                return;
                                // Check for rate limiting.
                            } else if (retryStatusCodes.has(res.statusCode)) {
                                if (!retryRequest({
                                        retryAfter: parseInt(res.headers['retry-after'] || '0', 10)
                                    })) {
                                    let err = new Miniget.MinigetError(`Status code: ${res.statusCode}`, res.statusCode);
                                    stream.emit('error', err);
                                }
                                cleanup();
                                return;
                            } else if (res.statusCode && (res.statusCode < 200 || res.statusCode >= 400)) {
                                let err = new Miniget.MinigetError(`Status code: ${res.statusCode}`, res.statusCode);
                                if (res.statusCode >= 500) {
                                    onError(err);
                                } else {
                                    stream.emit('error', err);
                                }
                                cleanup();
                                return;
                            }
                            activeDecodedStream = res;
                            if (opts.acceptEncoding && res.headers['content-encoding']) {
                                for (let enc of res.headers['content-encoding'].split(', ').reverse()) {
                                    let fn = opts.acceptEncoding[enc];
                                    if (fn) {
                                        activeDecodedStream = activeDecodedStream.pipe(fn());
                                        activeDecodedStream.on('error', onError);
                                    }
                                }
                            }
                            if (!contentLength) {
                                contentLength = parseInt(`${res.headers['content-length']}`, 10);
                                acceptRanges = res.headers['accept-ranges'] === 'bytes' &&
                                    contentLength > 0 && opts.maxReconnects > 0;
                            }
                            res.on('data', onData);
                            activeDecodedStream.on('end', onEnd);
                            activeDecodedStream.pipe(stream, {
                                end: !acceptRanges
                            });
                            activeResponse = res;
                            stream.emit('response', res);
                            res.on('error', onError);
                            forwardEvents(res, responseEvents);
                        });
                        activeRequest.on('error', onError);
                        activeRequest.on('close', onRequestClose);
                        forwardEvents(activeRequest, requestEvents);
                        if (stream.destroyed) {
                            streamDestroy(...destroyArgs);
                        }
                        stream.emit('request', activeRequest);
                        activeRequest.end();
                    };
                    stream.abort = (err) => {
                        console.warn('`MinigetStream#abort()` has been deprecated in favor of `MinigetStream#destroy()`');
                        stream.aborted = true;
                        stream.emit('abort');
                        stream.destroy(err);
                    };
                    let destroyArgs;
                    const streamDestroy = (err) => {
                        activeRequest.destroy(err);
                        activeDecodedStream === null || activeDecodedStream === void 0 ? void 0 : activeDecodedStream.unpipe(stream);
                        activeDecodedStream === null || activeDecodedStream === void 0 ? void 0 : activeDecodedStream.destroy();
                        clearTimeout(retryTimeout);
                    };
                    stream._destroy = (...args) => {
                        stream.destroyed = true;
                        if (activeRequest) {
                            streamDestroy(...args);
                        } else {
                            destroyArgs = args;
                        }
                    };
                    stream.text = () => new Promise((resolve, reject) => {
                        let body = '';
                        stream.setEncoding('utf8');
                        stream.on('data', chunk => body += chunk);
                        stream.on('end', () => resolve(body));
                        stream.on('error', reject);
                    });
                    process.nextTick(doDownload);
                    return stream;
                }
                module.exports = Miniget;

            }).call(this)
        }).call(this, require('_process'))
    }, {
        "_process": 9,
        "http": 30,
        "https": 6,
        "stream": 15
    }],
    63: [function(require, module, exports) {
        (function(Buffer) {
            (function() {
                ;
                (function(sax) { // wrapper for non-node envs
                    sax.parser = function(strict, opt) {
                        return new SAXParser(strict, opt)
                    }
                    sax.SAXParser = SAXParser
                    sax.SAXStream = SAXStream
                    sax.createStream = createStream

                    // When we pass the MAX_BUFFER_LENGTH position, start checking for buffer overruns.
                    // When we check, schedule the next check for MAX_BUFFER_LENGTH - (max(buffer lengths)),
                    // since that's the earliest that a buffer overrun could occur.  This way, checks are
                    // as rare as required, but as often as necessary to ensure never crossing this bound.
                    // Furthermore, buffers are only tested at most once per write(), so passing a very
                    // large string into write() might have undesirable effects, but this is manageable by
                    // the caller, so it is assumed to be safe.  Thus, a call to write() may, in the extreme
                    // edge case, result in creating at most one complete copy of the string passed in.
                    // Set to Infinity to have unlimited buffers.
                    sax.MAX_BUFFER_LENGTH = 64 * 1024

                    var buffers = [
                        'comment', 'sgmlDecl', 'textNode', 'tagName', 'doctype',
                        'procInstName', 'procInstBody', 'entity', 'attribName',
                        'attribValue', 'cdata', 'script'
                    ]

                    sax.EVENTS = [
                        'text',
                        'processinginstruction',
                        'sgmldeclaration',
                        'doctype',
                        'comment',
                        'opentagstart',
                        'attribute',
                        'opentag',
                        'closetag',
                        'opencdata',
                        'cdata',
                        'closecdata',
                        'error',
                        'end',
                        'ready',
                        'script',
                        'opennamespace',
                        'closenamespace'
                    ]

                    function SAXParser(strict, opt) {
                        if (!(this instanceof SAXParser)) {
                            return new SAXParser(strict, opt)
                        }

                        var parser = this
                        clearBuffers(parser)
                        parser.q = parser.c = ''
                        parser.bufferCheckPosition = sax.MAX_BUFFER_LENGTH
                        parser.opt = opt || {}
                        parser.opt.lowercase = parser.opt.lowercase || parser.opt.lowercasetags
                        parser.looseCase = parser.opt.lowercase ? 'toLowerCase' : 'toUpperCase'
                        parser.tags = []
                        parser.closed = parser.closedRoot = parser.sawRoot = false
                        parser.tag = parser.error = null
                        parser.strict = !!strict
                        parser.noscript = !!(strict || parser.opt.noscript)
                        parser.state = S.BEGIN
                        parser.strictEntities = parser.opt.strictEntities
                        parser.ENTITIES = parser.strictEntities ? Object.create(sax.XML_ENTITIES) : Object.create(sax.ENTITIES)
                        parser.attribList = []

                        // namespaces form a prototype chain.
                        // it always points at the current tag,
                        // which protos to its parent tag.
                        if (parser.opt.xmlns) {
                            parser.ns = Object.create(rootNS)
                        }

                        // mostly just for error reporting
                        parser.trackPosition = parser.opt.position !== false
                        if (parser.trackPosition) {
                            parser.position = parser.line = parser.column = 0
                        }
                        emit(parser, 'onready')
                    }

                    if (!Object.create) {
                        Object.create = function(o) {
                            function F() {}
                            F.prototype = o
                            var newf = new F()
                            return newf
                        }
                    }

                    if (!Object.keys) {
                        Object.keys = function(o) {
                            var a = []
                            for (var i in o)
                                if (o.hasOwnProperty(i)) a.push(i)
                            return a
                        }
                    }

                    function checkBufferLength(parser) {
                        var maxAllowed = Math.max(sax.MAX_BUFFER_LENGTH, 10)
                        var maxActual = 0
                        for (var i = 0, l = buffers.length; i < l; i++) {
                            var len = parser[buffers[i]].length
                            if (len > maxAllowed) {
                                // Text/cdata nodes can get big, and since they're buffered,
                                // we can get here under normal conditions.
                                // Avoid issues by emitting the text node now,
                                // so at least it won't get any bigger.
                                switch (buffers[i]) {
                                    case 'textNode':
                                        closeText(parser)
                                        break

                                    case 'cdata':
                                        emitNode(parser, 'oncdata', parser.cdata)
                                        parser.cdata = ''
                                        break

                                    case 'script':
                                        emitNode(parser, 'onscript', parser.script)
                                        parser.script = ''
                                        break

                                    default:
                                        error(parser, 'Max buffer length exceeded: ' + buffers[i])
                                }
                            }
                            maxActual = Math.max(maxActual, len)
                        }
                        // schedule the next check for the earliest possible buffer overrun.
                        var m = sax.MAX_BUFFER_LENGTH - maxActual
                        parser.bufferCheckPosition = m + parser.position
                    }

                    function clearBuffers(parser) {
                        for (var i = 0, l = buffers.length; i < l; i++) {
                            parser[buffers[i]] = ''
                        }
                    }

                    function flushBuffers(parser) {
                        closeText(parser)
                        if (parser.cdata !== '') {
                            emitNode(parser, 'oncdata', parser.cdata)
                            parser.cdata = ''
                        }
                        if (parser.script !== '') {
                            emitNode(parser, 'onscript', parser.script)
                            parser.script = ''
                        }
                    }

                    SAXParser.prototype = {
                        end: function() {
                            end(this)
                        },
                        write: write,
                        resume: function() {
                            this.error = null;
                            return this
                        },
                        close: function() {
                            return this.write(null)
                        },
                        flush: function() {
                            flushBuffers(this)
                        }
                    }

                    var Stream
                    try {
                        Stream = require('stream').Stream
                    } catch (ex) {
                        Stream = function() {}
                    }

                    var streamWraps = sax.EVENTS.filter(function(ev) {
                        return ev !== 'error' && ev !== 'end'
                    })

                    function createStream(strict, opt) {
                        return new SAXStream(strict, opt)
                    }

                    function SAXStream(strict, opt) {
                        if (!(this instanceof SAXStream)) {
                            return new SAXStream(strict, opt)
                        }

                        Stream.apply(this)

                        this._parser = new SAXParser(strict, opt)
                        this.writable = true
                        this.readable = true

                        var me = this

                        this._parser.onend = function() {
                            me.emit('end')
                        }

                        this._parser.onerror = function(er) {
                            me.emit('error', er)

                            // if didn't throw, then means error was handled.
                            // go ahead and clear error, so we can write again.
                            me._parser.error = null
                        }

                        this._decoder = null

                        streamWraps.forEach(function(ev) {
                            Object.defineProperty(me, 'on' + ev, {
                                get: function() {
                                    return me._parser['on' + ev]
                                },
                                set: function(h) {
                                    if (!h) {
                                        me.removeAllListeners(ev)
                                        me._parser['on' + ev] = h
                                        return h
                                    }
                                    me.on(ev, h)
                                },
                                enumerable: true,
                                configurable: false
                            })
                        })
                    }

                    SAXStream.prototype = Object.create(Stream.prototype, {
                        constructor: {
                            value: SAXStream
                        }
                    })

                    SAXStream.prototype.write = function(data) {
                        if (typeof Buffer === 'function' &&
                            typeof Buffer.isBuffer === 'function' &&
                            Buffer.isBuffer(data)) {
                            if (!this._decoder) {
                                var SD = require('string_decoder').StringDecoder
                                this._decoder = new SD('utf8')
                            }
                            data = this._decoder.write(data)
                        }

                        this._parser.write(data.toString())
                        this.emit('data', data)
                        return true
                    }

                    SAXStream.prototype.end = function(chunk) {
                        if (chunk && chunk.length) {
                            this.write(chunk)
                        }
                        this._parser.end()
                        return true
                    }

                    SAXStream.prototype.on = function(ev, handler) {
                        var me = this
                        if (!me._parser['on' + ev] && streamWraps.indexOf(ev) !== -1) {
                            me._parser['on' + ev] = function() {
                                var args = arguments.length === 1 ? [arguments[0]] : Array.apply(null, arguments)
                                args.splice(0, 0, ev)
                                me.emit.apply(me, args)
                            }
                        }

                        return Stream.prototype.on.call(me, ev, handler)
                    }

                    // this really needs to be replaced with character classes.
                    // XML allows all manner of ridiculous numbers and digits.
                    var CDATA = '[CDATA['
                    var DOCTYPE = 'DOCTYPE'
                    var XML_NAMESPACE = 'http://www.w3.org/XML/1998/namespace'
                    var XMLNS_NAMESPACE = 'http://www.w3.org/2000/xmlns/'
                    var rootNS = {
                        xml: XML_NAMESPACE,
                        xmlns: XMLNS_NAMESPACE
                    }

                    // http://www.w3.org/TR/REC-xml/#NT-NameStartChar
                    // This implementation works on strings, a single character at a time
                    // as such, it cannot ever support astral-plane characters (10000-EFFFF)
                    // without a significant breaking change to either this  parser, or the
                    // JavaScript language.  Implementation of an emoji-capable xml parser
                    // is left as an exercise for the reader.
                    var nameStart = /[:_A-Za-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]/

                    var nameBody = /[:_A-Za-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD\u00B7\u0300-\u036F\u203F-\u2040.\d-]/

                    var entityStart = /[#:_A-Za-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD]/
                    var entityBody = /[#:_A-Za-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02FF\u0370-\u037D\u037F-\u1FFF\u200C-\u200D\u2070-\u218F\u2C00-\u2FEF\u3001-\uD7FF\uF900-\uFDCF\uFDF0-\uFFFD\u00B7\u0300-\u036F\u203F-\u2040.\d-]/

                    function isWhitespace(c) {
                        return c === ' ' || c === '\n' || c === '\r' || c === '\t'
                    }

                    function isQuote(c) {
                        return c === '"' || c === '\''
                    }

                    function isAttribEnd(c) {
                        return c === '>' || isWhitespace(c)
                    }

                    function isMatch(regex, c) {
                        return regex.test(c)
                    }

                    function notMatch(regex, c) {
                        return !isMatch(regex, c)
                    }

                    var S = 0
                    sax.STATE = {
                        BEGIN: S++, // leading byte order mark or whitespace
                        BEGIN_WHITESPACE: S++, // leading whitespace
                        TEXT: S++, // general stuff
                        TEXT_ENTITY: S++, // &amp and such.
                        OPEN_WAKA: S++, // <
                        SGML_DECL: S++, // <!BLARG
                        SGML_DECL_QUOTED: S++, // <!BLARG foo "bar
                        DOCTYPE: S++, // <!DOCTYPE
                        DOCTYPE_QUOTED: S++, // <!DOCTYPE "//blah
                        DOCTYPE_DTD: S++, // <!DOCTYPE "//blah" [ ...
                        DOCTYPE_DTD_QUOTED: S++, // <!DOCTYPE "//blah" [ "foo
                        COMMENT_STARTING: S++, // <!-
                        COMMENT: S++, // <!--
                        COMMENT_ENDING: S++, // <!-- blah -
                        COMMENT_ENDED: S++, // <!-- blah --
                        CDATA: S++, // <![CDATA[ something
                        CDATA_ENDING: S++, // ]
                        CDATA_ENDING_2: S++, // ]]
                        PROC_INST: S++, // <?hi
                        PROC_INST_BODY: S++, // <?hi there
                        PROC_INST_ENDING: S++, // <?hi "there" ?
                        OPEN_TAG: S++, // <strong
                        OPEN_TAG_SLASH: S++, // <strong /
                        ATTRIB: S++, // <a
                        ATTRIB_NAME: S++, // <a foo
                        ATTRIB_NAME_SAW_WHITE: S++, // <a foo _
                        ATTRIB_VALUE: S++, // <a foo=
                        ATTRIB_VALUE_QUOTED: S++, // <a foo="bar
                        ATTRIB_VALUE_CLOSED: S++, // <a foo="bar"
                        ATTRIB_VALUE_UNQUOTED: S++, // <a foo=bar
                        ATTRIB_VALUE_ENTITY_Q: S++, // <foo bar="&quot;"
                        ATTRIB_VALUE_ENTITY_U: S++, // <foo bar=&quot
                        CLOSE_TAG: S++, // </a
                        CLOSE_TAG_SAW_WHITE: S++, // </a   >
                        SCRIPT: S++, // <script> ...
                        SCRIPT_ENDING: S++ // <script> ... <
                    }

                    sax.XML_ENTITIES = {
                        'amp': '&',
                        'gt': '>',
                        'lt': '<',
                        'quot': '"',
                        'apos': "'"
                    }

                    sax.ENTITIES = {
                        'amp': '&',
                        'gt': '>',
                        'lt': '<',
                        'quot': '"',
                        'apos': "'",
                        'AElig': 198,
                        'Aacute': 193,
                        'Acirc': 194,
                        'Agrave': 192,
                        'Aring': 197,
                        'Atilde': 195,
                        'Auml': 196,
                        'Ccedil': 199,
                        'ETH': 208,
                        'Eacute': 201,
                        'Ecirc': 202,
                        'Egrave': 200,
                        'Euml': 203,
                        'Iacute': 205,
                        'Icirc': 206,
                        'Igrave': 204,
                        'Iuml': 207,
                        'Ntilde': 209,
                        'Oacute': 211,
                        'Ocirc': 212,
                        'Ograve': 210,
                        'Oslash': 216,
                        'Otilde': 213,
                        'Ouml': 214,
                        'THORN': 222,
                        'Uacute': 218,
                        'Ucirc': 219,
                        'Ugrave': 217,
                        'Uuml': 220,
                        'Yacute': 221,
                        'aacute': 225,
                        'acirc': 226,
                        'aelig': 230,
                        'agrave': 224,
                        'aring': 229,
                        'atilde': 227,
                        'auml': 228,
                        'ccedil': 231,
                        'eacute': 233,
                        'ecirc': 234,
                        'egrave': 232,
                        'eth': 240,
                        'euml': 235,
                        'iacute': 237,
                        'icirc': 238,
                        'igrave': 236,
                        'iuml': 239,
                        'ntilde': 241,
                        'oacute': 243,
                        'ocirc': 244,
                        'ograve': 242,
                        'oslash': 248,
                        'otilde': 245,
                        'ouml': 246,
                        'szlig': 223,
                        'thorn': 254,
                        'uacute': 250,
                        'ucirc': 251,
                        'ugrave': 249,
                        'uuml': 252,
                        'yacute': 253,
                        'yuml': 255,
                        'copy': 169,
                        'reg': 174,
                        'nbsp': 160,
                        'iexcl': 161,
                        'cent': 162,
                        'pound': 163,
                        'curren': 164,
                        'yen': 165,
                        'brvbar': 166,
                        'sect': 167,
                        'uml': 168,
                        'ordf': 170,
                        'laquo': 171,
                        'not': 172,
                        'shy': 173,
                        'macr': 175,
                        'deg': 176,
                        'plusmn': 177,
                        'sup1': 185,
                        'sup2': 178,
                        'sup3': 179,
                        'acute': 180,
                        'micro': 181,
                        'para': 182,
                        'middot': 183,
                        'cedil': 184,
                        'ordm': 186,
                        'raquo': 187,
                        'frac14': 188,
                        'frac12': 189,
                        'frac34': 190,
                        'iquest': 191,
                        'times': 215,
                        'divide': 247,
                        'OElig': 338,
                        'oelig': 339,
                        'Scaron': 352,
                        'scaron': 353,
                        'Yuml': 376,
                        'fnof': 402,
                        'circ': 710,
                        'tilde': 732,
                        'Alpha': 913,
                        'Beta': 914,
                        'Gamma': 915,
                        'Delta': 916,
                        'Epsilon': 917,
                        'Zeta': 918,
                        'Eta': 919,
                        'Theta': 920,
                        'Iota': 921,
                        'Kappa': 922,
                        'Lambda': 923,
                        'Mu': 924,
                        'Nu': 925,
                        'Xi': 926,
                        'Omicron': 927,
                        'Pi': 928,
                        'Rho': 929,
                        'Sigma': 931,
                        'Tau': 932,
                        'Upsilon': 933,
                        'Phi': 934,
                        'Chi': 935,
                        'Psi': 936,
                        'Omega': 937,
                        'alpha': 945,
                        'beta': 946,
                        'gamma': 947,
                        'delta': 948,
                        'epsilon': 949,
                        'zeta': 950,
                        'eta': 951,
                        'theta': 952,
                        'iota': 953,
                        'kappa': 954,
                        'lambda': 955,
                        'mu': 956,
                        'nu': 957,
                        'xi': 958,
                        'omicron': 959,
                        'pi': 960,
                        'rho': 961,
                        'sigmaf': 962,
                        'sigma': 963,
                        'tau': 964,
                        'upsilon': 965,
                        'phi': 966,
                        'chi': 967,
                        'psi': 968,
                        'omega': 969,
                        'thetasym': 977,
                        'upsih': 978,
                        'piv': 982,
                        'ensp': 8194,
                        'emsp': 8195,
                        'thinsp': 8201,
                        'zwnj': 8204,
                        'zwj': 8205,
                        'lrm': 8206,
                        'rlm': 8207,
                        'ndash': 8211,
                        'mdash': 8212,
                        'lsquo': 8216,
                        'rsquo': 8217,
                        'sbquo': 8218,
                        'ldquo': 8220,
                        'rdquo': 8221,
                        'bdquo': 8222,
                        'dagger': 8224,
                        'Dagger': 8225,
                        'bull': 8226,
                        'hellip': 8230,
                        'permil': 8240,
                        'prime': 8242,
                        'Prime': 8243,
                        'lsaquo': 8249,
                        'rsaquo': 8250,
                        'oline': 8254,
                        'frasl': 8260,
                        'euro': 8364,
                        'image': 8465,
                        'weierp': 8472,
                        'real': 8476,
                        'trade': 8482,
                        'alefsym': 8501,
                        'larr': 8592,
                        'uarr': 8593,
                        'rarr': 8594,
                        'darr': 8595,
                        'harr': 8596,
                        'crarr': 8629,
                        'lArr': 8656,
                        'uArr': 8657,
                        'rArr': 8658,
                        'dArr': 8659,
                        'hArr': 8660,
                        'forall': 8704,
                        'part': 8706,
                        'exist': 8707,
                        'empty': 8709,
                        'nabla': 8711,
                        'isin': 8712,
                        'notin': 8713,
                        'ni': 8715,
                        'prod': 8719,
                        'sum': 8721,
                        'minus': 8722,
                        'lowast': 8727,
                        'radic': 8730,
                        'prop': 8733,
                        'infin': 8734,
                        'ang': 8736,
                        'and': 8743,
                        'or': 8744,
                        'cap': 8745,
                        'cup': 8746,
                        'int': 8747,
                        'there4': 8756,
                        'sim': 8764,
                        'cong': 8773,
                        'asymp': 8776,
                        'ne': 8800,
                        'equiv': 8801,
                        'le': 8804,
                        'ge': 8805,
                        'sub': 8834,
                        'sup': 8835,
                        'nsub': 8836,
                        'sube': 8838,
                        'supe': 8839,
                        'oplus': 8853,
                        'otimes': 8855,
                        'perp': 8869,
                        'sdot': 8901,
                        'lceil': 8968,
                        'rceil': 8969,
                        'lfloor': 8970,
                        'rfloor': 8971,
                        'lang': 9001,
                        'rang': 9002,
                        'loz': 9674,
                        'spades': 9824,
                        'clubs': 9827,
                        'hearts': 9829,
                        'diams': 9830
                    }

                    Object.keys(sax.ENTITIES).forEach(function(key) {
                        var e = sax.ENTITIES[key]
                        var s = typeof e === 'number' ? String.fromCharCode(e) : e
                        sax.ENTITIES[key] = s
                    })

                    for (var s in sax.STATE) {
                        sax.STATE[sax.STATE[s]] = s
                    }

                    // shorthand
                    S = sax.STATE

                    function emit(parser, event, data) {
                        parser[event] && parser[event](data)
                    }

                    function emitNode(parser, nodeType, data) {
                        if (parser.textNode) closeText(parser)
                        emit(parser, nodeType, data)
                    }

                    function closeText(parser) {
                        parser.textNode = textopts(parser.opt, parser.textNode)
                        if (parser.textNode) emit(parser, 'ontext', parser.textNode)
                        parser.textNode = ''
                    }

                    function textopts(opt, text) {
                        if (opt.trim) text = text.trim()
                        if (opt.normalize) text = text.replace(/\s+/g, ' ')
                        return text
                    }

                    function error(parser, er) {
                        closeText(parser)
                        if (parser.trackPosition) {
                            er += '\nLine: ' + parser.line +
                                '\nColumn: ' + parser.column +
                                '\nChar: ' + parser.c
                        }
                        er = new Error(er)
                        parser.error = er
                        emit(parser, 'onerror', er)
                        return parser
                    }

                    function end(parser) {
                        if (parser.sawRoot && !parser.closedRoot) strictFail(parser, 'Unclosed root tag')
                        if ((parser.state !== S.BEGIN) &&
                            (parser.state !== S.BEGIN_WHITESPACE) &&
                            (parser.state !== S.TEXT)) {
                            error(parser, 'Unexpected end')
                        }
                        closeText(parser)
                        parser.c = ''
                        parser.closed = true
                        emit(parser, 'onend')
                        SAXParser.call(parser, parser.strict, parser.opt)
                        return parser
                    }

                    function strictFail(parser, message) {
                        if (typeof parser !== 'object' || !(parser instanceof SAXParser)) {
                            throw new Error('bad call to strictFail')
                        }
                        if (parser.strict) {
                            error(parser, message)
                        }
                    }

                    function newTag(parser) {
                        if (!parser.strict) parser.tagName = parser.tagName[parser.looseCase]()
                        var parent = parser.tags[parser.tags.length - 1] || parser
                        var tag = parser.tag = {
                            name: parser.tagName,
                            attributes: {}
                        }

                        // will be overridden if tag contails an xmlns="foo" or xmlns:foo="bar"
                        if (parser.opt.xmlns) {
                            tag.ns = parent.ns
                        }
                        parser.attribList.length = 0
                        emitNode(parser, 'onopentagstart', tag)
                    }

                    function qname(name, attribute) {
                        var i = name.indexOf(':')
                        var qualName = i < 0 ? ['', name] : name.split(':')
                        var prefix = qualName[0]
                        var local = qualName[1]

                        // <x "xmlns"="http://foo">
                        if (attribute && name === 'xmlns') {
                            prefix = 'xmlns'
                            local = ''
                        }

                        return {
                            prefix: prefix,
                            local: local
                        }
                    }

                    function attrib(parser) {
                        if (!parser.strict) {
                            parser.attribName = parser.attribName[parser.looseCase]()
                        }

                        if (parser.attribList.indexOf(parser.attribName) !== -1 ||
                            parser.tag.attributes.hasOwnProperty(parser.attribName)) {
                            parser.attribName = parser.attribValue = ''
                            return
                        }

                        if (parser.opt.xmlns) {
                            var qn = qname(parser.attribName, true)
                            var prefix = qn.prefix
                            var local = qn.local

                            if (prefix === 'xmlns') {
                                // namespace binding attribute. push the binding into scope
                                if (local === 'xml' && parser.attribValue !== XML_NAMESPACE) {
                                    strictFail(parser,
                                        'xml: prefix must be bound to ' + XML_NAMESPACE + '\n' +
                                        'Actual: ' + parser.attribValue)
                                } else if (local === 'xmlns' && parser.attribValue !== XMLNS_NAMESPACE) {
                                    strictFail(parser,
                                        'xmlns: prefix must be bound to ' + XMLNS_NAMESPACE + '\n' +
                                        'Actual: ' + parser.attribValue)
                                } else {
                                    var tag = parser.tag
                                    var parent = parser.tags[parser.tags.length - 1] || parser
                                    if (tag.ns === parent.ns) {
                                        tag.ns = Object.create(parent.ns)
                                    }
                                    tag.ns[local] = parser.attribValue
                                }
                            }

                            // defer onattribute events until all attributes have been seen
                            // so any new bindings can take effect. preserve attribute order
                            // so deferred events can be emitted in document order
                            parser.attribList.push([parser.attribName, parser.attribValue])
                        } else {
                            // in non-xmlns mode, we can emit the event right away
                            parser.tag.attributes[parser.attribName] = parser.attribValue
                            emitNode(parser, 'onattribute', {
                                name: parser.attribName,
                                value: parser.attribValue
                            })
                        }

                        parser.attribName = parser.attribValue = ''
                    }

                    function openTag(parser, selfClosing) {
                        if (parser.opt.xmlns) {
                            // emit namespace binding events
                            var tag = parser.tag

                            // add namespace info to tag
                            var qn = qname(parser.tagName)
                            tag.prefix = qn.prefix
                            tag.local = qn.local
                            tag.uri = tag.ns[qn.prefix] || ''

                            if (tag.prefix && !tag.uri) {
                                strictFail(parser, 'Unbound namespace prefix: ' +
                                    JSON.stringify(parser.tagName))
                                tag.uri = qn.prefix
                            }

                            var parent = parser.tags[parser.tags.length - 1] || parser
                            if (tag.ns && parent.ns !== tag.ns) {
                                Object.keys(tag.ns).forEach(function(p) {
                                    emitNode(parser, 'onopennamespace', {
                                        prefix: p,
                                        uri: tag.ns[p]
                                    })
                                })
                            }

                            // handle deferred onattribute events
                            // Note: do not apply default ns to attributes:
                            //   http://www.w3.org/TR/REC-xml-names/#defaulting
                            for (var i = 0, l = parser.attribList.length; i < l; i++) {
                                var nv = parser.attribList[i]
                                var name = nv[0]
                                var value = nv[1]
                                var qualName = qname(name, true)
                                var prefix = qualName.prefix
                                var local = qualName.local
                                var uri = prefix === '' ? '' : (tag.ns[prefix] || '')
                                var a = {
                                    name: name,
                                    value: value,
                                    prefix: prefix,
                                    local: local,
                                    uri: uri
                                }

                                // if there's any attributes with an undefined namespace,
                                // then fail on them now.
                                if (prefix && prefix !== 'xmlns' && !uri) {
                                    strictFail(parser, 'Unbound namespace prefix: ' +
                                        JSON.stringify(prefix))
                                    a.uri = prefix
                                }
                                parser.tag.attributes[name] = a
                                emitNode(parser, 'onattribute', a)
                            }
                            parser.attribList.length = 0
                        }

                        parser.tag.isSelfClosing = !!selfClosing

                        // process the tag
                        parser.sawRoot = true
                        parser.tags.push(parser.tag)
                        emitNode(parser, 'onopentag', parser.tag)
                        if (!selfClosing) {
                            // special case for <script> in non-strict mode.
                            if (!parser.noscript && parser.tagName.toLowerCase() === 'script') {
                                parser.state = S.SCRIPT
                            } else {
                                parser.state = S.TEXT
                            }
                            parser.tag = null
                            parser.tagName = ''
                        }
                        parser.attribName = parser.attribValue = ''
                        parser.attribList.length = 0
                    }

                    function closeTag(parser) {
                        if (!parser.tagName) {
                            strictFail(parser, 'Weird empty close tag.')
                            parser.textNode += '</>'
                            parser.state = S.TEXT
                            return
                        }

                        if (parser.script) {
                            if (parser.tagName !== 'script') {
                                parser.script += '</' + parser.tagName + '>'
                                parser.tagName = ''
                                parser.state = S.SCRIPT
                                return
                            }
                            emitNode(parser, 'onscript', parser.script)
                            parser.script = ''
                        }

                        // first make sure that the closing tag actually exists.
                        // <a><b></c></b></a> will close everything, otherwise.
                        var t = parser.tags.length
                        var tagName = parser.tagName
                        if (!parser.strict) {
                            tagName = tagName[parser.looseCase]()
                        }
                        var closeTo = tagName
                        while (t--) {
                            var close = parser.tags[t]
                            if (close.name !== closeTo) {
                                // fail the first time in strict mode
                                strictFail(parser, 'Unexpected close tag')
                            } else {
                                break
                            }
                        }

                        // didn't find it.  we already failed for strict, so just abort.
                        if (t < 0) {
                            strictFail(parser, 'Unmatched closing tag: ' + parser.tagName)
                            parser.textNode += '</' + parser.tagName + '>'
                            parser.state = S.TEXT
                            return
                        }
                        parser.tagName = tagName
                        var s = parser.tags.length
                        while (s-- > t) {
                            var tag = parser.tag = parser.tags.pop()
                            parser.tagName = parser.tag.name
                            emitNode(parser, 'onclosetag', parser.tagName)

                            var x = {}
                            for (var i in tag.ns) {
                                x[i] = tag.ns[i]
                            }

                            var parent = parser.tags[parser.tags.length - 1] || parser
                            if (parser.opt.xmlns && tag.ns !== parent.ns) {
                                // remove namespace bindings introduced by tag
                                Object.keys(tag.ns).forEach(function(p) {
                                    var n = tag.ns[p]
                                    emitNode(parser, 'onclosenamespace', {
                                        prefix: p,
                                        uri: n
                                    })
                                })
                            }
                        }
                        if (t === 0) parser.closedRoot = true
                        parser.tagName = parser.attribValue = parser.attribName = ''
                        parser.attribList.length = 0
                        parser.state = S.TEXT
                    }

                    function parseEntity(parser) {
                        var entity = parser.entity
                        var entityLC = entity.toLowerCase()
                        var num
                        var numStr = ''

                        if (parser.ENTITIES[entity]) {
                            return parser.ENTITIES[entity]
                        }
                        if (parser.ENTITIES[entityLC]) {
                            return parser.ENTITIES[entityLC]
                        }
                        entity = entityLC
                        if (entity.charAt(0) === '#') {
                            if (entity.charAt(1) === 'x') {
                                entity = entity.slice(2)
                                num = parseInt(entity, 16)
                                numStr = num.toString(16)
                            } else {
                                entity = entity.slice(1)
                                num = parseInt(entity, 10)
                                numStr = num.toString(10)
                            }
                        }
                        entity = entity.replace(/^0+/, '')
                        if (isNaN(num) || numStr.toLowerCase() !== entity) {
                            strictFail(parser, 'Invalid character entity')
                            return '&' + parser.entity + ';'
                        }

                        return String.fromCodePoint(num)
                    }

                    function beginWhiteSpace(parser, c) {
                        if (c === '<') {
                            parser.state = S.OPEN_WAKA
                            parser.startTagPosition = parser.position
                        } else if (!isWhitespace(c)) {
                            // have to process this as a text node.
                            // weird, but happens.
                            strictFail(parser, 'Non-whitespace before first tag.')
                            parser.textNode = c
                            parser.state = S.TEXT
                        }
                    }

                    function charAt(chunk, i) {
                        var result = ''
                        if (i < chunk.length) {
                            result = chunk.charAt(i)
                        }
                        return result
                    }

                    function write(chunk) {
                        var parser = this
                        if (this.error) {
                            throw this.error
                        }
                        if (parser.closed) {
                            return error(parser,
                                'Cannot write after close. Assign an onready handler.')
                        }
                        if (chunk === null) {
                            return end(parser)
                        }
                        if (typeof chunk === 'object') {
                            chunk = chunk.toString()
                        }
                        var i = 0
                        var c = ''
                        while (true) {
                            c = charAt(chunk, i++)
                            parser.c = c

                            if (!c) {
                                break
                            }

                            if (parser.trackPosition) {
                                parser.position++
                                if (c === '\n') {
                                    parser.line++
                                    parser.column = 0
                                } else {
                                    parser.column++
                                }
                            }

                            switch (parser.state) {
                                case S.BEGIN:
                                    parser.state = S.BEGIN_WHITESPACE
                                    if (c === '\uFEFF') {
                                        continue
                                    }
                                    beginWhiteSpace(parser, c)
                                    continue

                                case S.BEGIN_WHITESPACE:
                                    beginWhiteSpace(parser, c)
                                    continue

                                case S.TEXT:
                                    if (parser.sawRoot && !parser.closedRoot) {
                                        var starti = i - 1
                                        while (c && c !== '<' && c !== '&') {
                                            c = charAt(chunk, i++)
                                            if (c && parser.trackPosition) {
                                                parser.position++
                                                if (c === '\n') {
                                                    parser.line++
                                                    parser.column = 0
                                                } else {
                                                    parser.column++
                                                }
                                            }
                                        }
                                        parser.textNode += chunk.substring(starti, i - 1)
                                    }
                                    if (c === '<' && !(parser.sawRoot && parser.closedRoot && !parser.strict)) {
                                        parser.state = S.OPEN_WAKA
                                        parser.startTagPosition = parser.position
                                    } else {
                                        if (!isWhitespace(c) && (!parser.sawRoot || parser.closedRoot)) {
                                            strictFail(parser, 'Text data outside of root node.')
                                        }
                                        if (c === '&') {
                                            parser.state = S.TEXT_ENTITY
                                        } else {
                                            parser.textNode += c
                                        }
                                    }
                                    continue

                                case S.SCRIPT:
                                    // only non-strict
                                    if (c === '<') {
                                        parser.state = S.SCRIPT_ENDING
                                    } else {
                                        parser.script += c
                                    }
                                    continue

                                case S.SCRIPT_ENDING:
                                    if (c === '/') {
                                        parser.state = S.CLOSE_TAG
                                    } else {
                                        parser.script += '<' + c
                                        parser.state = S.SCRIPT
                                    }
                                    continue

                                case S.OPEN_WAKA:
                                    // either a /, ?, !, or text is coming next.
                                    if (c === '!') {
                                        parser.state = S.SGML_DECL
                                        parser.sgmlDecl = ''
                                    } else if (isWhitespace(c)) {
                                        // wait for it...
                                    } else if (isMatch(nameStart, c)) {
                                        parser.state = S.OPEN_TAG
                                        parser.tagName = c
                                    } else if (c === '/') {
                                        parser.state = S.CLOSE_TAG
                                        parser.tagName = ''
                                    } else if (c === '?') {
                                        parser.state = S.PROC_INST
                                        parser.procInstName = parser.procInstBody = ''
                                    } else {
                                        strictFail(parser, 'Unencoded <')
                                        // if there was some whitespace, then add that in.
                                        if (parser.startTagPosition + 1 < parser.position) {
                                            var pad = parser.position - parser.startTagPosition
                                            c = new Array(pad).join(' ') + c
                                        }
                                        parser.textNode += '<' + c
                                        parser.state = S.TEXT
                                    }
                                    continue

                                case S.SGML_DECL:
                                    if ((parser.sgmlDecl + c).toUpperCase() === CDATA) {
                                        emitNode(parser, 'onopencdata')
                                        parser.state = S.CDATA
                                        parser.sgmlDecl = ''
                                        parser.cdata = ''
                                    } else if (parser.sgmlDecl + c === '--') {
                                        parser.state = S.COMMENT
                                        parser.comment = ''
                                        parser.sgmlDecl = ''
                                    } else if ((parser.sgmlDecl + c).toUpperCase() === DOCTYPE) {
                                        parser.state = S.DOCTYPE
                                        if (parser.doctype || parser.sawRoot) {
                                            strictFail(parser,
                                                'Inappropriately located doctype declaration')
                                        }
                                        parser.doctype = ''
                                        parser.sgmlDecl = ''
                                    } else if (c === '>') {
                                        emitNode(parser, 'onsgmldeclaration', parser.sgmlDecl)
                                        parser.sgmlDecl = ''
                                        parser.state = S.TEXT
                                    } else if (isQuote(c)) {
                                        parser.state = S.SGML_DECL_QUOTED
                                        parser.sgmlDecl += c
                                    } else {
                                        parser.sgmlDecl += c
                                    }
                                    continue

                                case S.SGML_DECL_QUOTED:
                                    if (c === parser.q) {
                                        parser.state = S.SGML_DECL
                                        parser.q = ''
                                    }
                                    parser.sgmlDecl += c
                                    continue

                                case S.DOCTYPE:
                                    if (c === '>') {
                                        parser.state = S.TEXT
                                        emitNode(parser, 'ondoctype', parser.doctype)
                                        parser.doctype = true // just remember that we saw it.
                                    } else {
                                        parser.doctype += c
                                        if (c === '[') {
                                            parser.state = S.DOCTYPE_DTD
                                        } else if (isQuote(c)) {
                                            parser.state = S.DOCTYPE_QUOTED
                                            parser.q = c
                                        }
                                    }
                                    continue

                                case S.DOCTYPE_QUOTED:
                                    parser.doctype += c
                                    if (c === parser.q) {
                                        parser.q = ''
                                        parser.state = S.DOCTYPE
                                    }
                                    continue

                                case S.DOCTYPE_DTD:
                                    parser.doctype += c
                                    if (c === ']') {
                                        parser.state = S.DOCTYPE
                                    } else if (isQuote(c)) {
                                        parser.state = S.DOCTYPE_DTD_QUOTED
                                        parser.q = c
                                    }
                                    continue

                                case S.DOCTYPE_DTD_QUOTED:
                                    parser.doctype += c
                                    if (c === parser.q) {
                                        parser.state = S.DOCTYPE_DTD
                                        parser.q = ''
                                    }
                                    continue

                                case S.COMMENT:
                                    if (c === '-') {
                                        parser.state = S.COMMENT_ENDING
                                    } else {
                                        parser.comment += c
                                    }
                                    continue

                                case S.COMMENT_ENDING:
                                    if (c === '-') {
                                        parser.state = S.COMMENT_ENDED
                                        parser.comment = textopts(parser.opt, parser.comment)
                                        if (parser.comment) {
                                            emitNode(parser, 'oncomment', parser.comment)
                                        }
                                        parser.comment = ''
                                    } else {
                                        parser.comment += '-' + c
                                        parser.state = S.COMMENT
                                    }
                                    continue

                                case S.COMMENT_ENDED:
                                    if (c !== '>') {
                                        strictFail(parser, 'Malformed comment')
                                        // allow <!-- blah -- bloo --> in non-strict mode,
                                        // which is a comment of " blah -- bloo "
                                        parser.comment += '--' + c
                                        parser.state = S.COMMENT
                                    } else {
                                        parser.state = S.TEXT
                                    }
                                    continue

                                case S.CDATA:
                                    if (c === ']') {
                                        parser.state = S.CDATA_ENDING
                                    } else {
                                        parser.cdata += c
                                    }
                                    continue

                                case S.CDATA_ENDING:
                                    if (c === ']') {
                                        parser.state = S.CDATA_ENDING_2
                                    } else {
                                        parser.cdata += ']' + c
                                        parser.state = S.CDATA
                                    }
                                    continue

                                case S.CDATA_ENDING_2:
                                    if (c === '>') {
                                        if (parser.cdata) {
                                            emitNode(parser, 'oncdata', parser.cdata)
                                        }
                                        emitNode(parser, 'onclosecdata')
                                        parser.cdata = ''
                                        parser.state = S.TEXT
                                    } else if (c === ']') {
                                        parser.cdata += ']'
                                    } else {
                                        parser.cdata += ']]' + c
                                        parser.state = S.CDATA
                                    }
                                    continue

                                case S.PROC_INST:
                                    if (c === '?') {
                                        parser.state = S.PROC_INST_ENDING
                                    } else if (isWhitespace(c)) {
                                        parser.state = S.PROC_INST_BODY
                                    } else {
                                        parser.procInstName += c
                                    }
                                    continue

                                case S.PROC_INST_BODY:
                                    if (!parser.procInstBody && isWhitespace(c)) {
                                        continue
                                    } else if (c === '?') {
                                        parser.state = S.PROC_INST_ENDING
                                    } else {
                                        parser.procInstBody += c
                                    }
                                    continue

                                case S.PROC_INST_ENDING:
                                    if (c === '>') {
                                        emitNode(parser, 'onprocessinginstruction', {
                                            name: parser.procInstName,
                                            body: parser.procInstBody
                                        })
                                        parser.procInstName = parser.procInstBody = ''
                                        parser.state = S.TEXT
                                    } else {
                                        parser.procInstBody += '?' + c
                                        parser.state = S.PROC_INST_BODY
                                    }
                                    continue

                                case S.OPEN_TAG:
                                    if (isMatch(nameBody, c)) {
                                        parser.tagName += c
                                    } else {
                                        newTag(parser)
                                        if (c === '>') {
                                            openTag(parser)
                                        } else if (c === '/') {
                                            parser.state = S.OPEN_TAG_SLASH
                                        } else {
                                            if (!isWhitespace(c)) {
                                                strictFail(parser, 'Invalid character in tag name')
                                            }
                                            parser.state = S.ATTRIB
                                        }
                                    }
                                    continue

                                case S.OPEN_TAG_SLASH:
                                    if (c === '>') {
                                        openTag(parser, true)
                                        closeTag(parser)
                                    } else {
                                        strictFail(parser, 'Forward-slash in opening tag not followed by >')
                                        parser.state = S.ATTRIB
                                    }
                                    continue

                                case S.ATTRIB:
                                    // haven't read the attribute name yet.
                                    if (isWhitespace(c)) {
                                        continue
                                    } else if (c === '>') {
                                        openTag(parser)
                                    } else if (c === '/') {
                                        parser.state = S.OPEN_TAG_SLASH
                                    } else if (isMatch(nameStart, c)) {
                                        parser.attribName = c
                                        parser.attribValue = ''
                                        parser.state = S.ATTRIB_NAME
                                    } else {
                                        strictFail(parser, 'Invalid attribute name')
                                    }
                                    continue

                                case S.ATTRIB_NAME:
                                    if (c === '=') {
                                        parser.state = S.ATTRIB_VALUE
                                    } else if (c === '>') {
                                        strictFail(parser, 'Attribute without value')
                                        parser.attribValue = parser.attribName
                                        attrib(parser)
                                        openTag(parser)
                                    } else if (isWhitespace(c)) {
                                        parser.state = S.ATTRIB_NAME_SAW_WHITE
                                    } else if (isMatch(nameBody, c)) {
                                        parser.attribName += c
                                    } else {
                                        strictFail(parser, 'Invalid attribute name')
                                    }
                                    continue

                                case S.ATTRIB_NAME_SAW_WHITE:
                                    if (c === '=') {
                                        parser.state = S.ATTRIB_VALUE
                                    } else if (isWhitespace(c)) {
                                        continue
                                    } else {
                                        strictFail(parser, 'Attribute without value')
                                        parser.tag.attributes[parser.attribName] = ''
                                        parser.attribValue = ''
                                        emitNode(parser, 'onattribute', {
                                            name: parser.attribName,
                                            value: ''
                                        })
                                        parser.attribName = ''
                                        if (c === '>') {
                                            openTag(parser)
                                        } else if (isMatch(nameStart, c)) {
                                            parser.attribName = c
                                            parser.state = S.ATTRIB_NAME
                                        } else {
                                            strictFail(parser, 'Invalid attribute name')
                                            parser.state = S.ATTRIB
                                        }
                                    }
                                    continue

                                case S.ATTRIB_VALUE:
                                    if (isWhitespace(c)) {
                                        continue
                                    } else if (isQuote(c)) {
                                        parser.q = c
                                        parser.state = S.ATTRIB_VALUE_QUOTED
                                    } else {
                                        strictFail(parser, 'Unquoted attribute value')
                                        parser.state = S.ATTRIB_VALUE_UNQUOTED
                                        parser.attribValue = c
                                    }
                                    continue

                                case S.ATTRIB_VALUE_QUOTED:
                                    if (c !== parser.q) {
                                        if (c === '&') {
                                            parser.state = S.ATTRIB_VALUE_ENTITY_Q
                                        } else {
                                            parser.attribValue += c
                                        }
                                        continue
                                    }
                                    attrib(parser)
                                    parser.q = ''
                                    parser.state = S.ATTRIB_VALUE_CLOSED
                                    continue

                                case S.ATTRIB_VALUE_CLOSED:
                                    if (isWhitespace(c)) {
                                        parser.state = S.ATTRIB
                                    } else if (c === '>') {
                                        openTag(parser)
                                    } else if (c === '/') {
                                        parser.state = S.OPEN_TAG_SLASH
                                    } else if (isMatch(nameStart, c)) {
                                        strictFail(parser, 'No whitespace between attributes')
                                        parser.attribName = c
                                        parser.attribValue = ''
                                        parser.state = S.ATTRIB_NAME
                                    } else {
                                        strictFail(parser, 'Invalid attribute name')
                                    }
                                    continue

                                case S.ATTRIB_VALUE_UNQUOTED:
                                    if (!isAttribEnd(c)) {
                                        if (c === '&') {
                                            parser.state = S.ATTRIB_VALUE_ENTITY_U
                                        } else {
                                            parser.attribValue += c
                                        }
                                        continue
                                    }
                                    attrib(parser)
                                    if (c === '>') {
                                        openTag(parser)
                                    } else {
                                        parser.state = S.ATTRIB
                                    }
                                    continue

                                case S.CLOSE_TAG:
                                    if (!parser.tagName) {
                                        if (isWhitespace(c)) {
                                            continue
                                        } else if (notMatch(nameStart, c)) {
                                            if (parser.script) {
                                                parser.script += '</' + c
                                                parser.state = S.SCRIPT
                                            } else {
                                                strictFail(parser, 'Invalid tagname in closing tag.')
                                            }
                                        } else {
                                            parser.tagName = c
                                        }
                                    } else if (c === '>') {
                                        closeTag(parser)
                                    } else if (isMatch(nameBody, c)) {
                                        parser.tagName += c
                                    } else if (parser.script) {
                                        parser.script += '</' + parser.tagName
                                        parser.tagName = ''
                                        parser.state = S.SCRIPT
                                    } else {
                                        if (!isWhitespace(c)) {
                                            strictFail(parser, 'Invalid tagname in closing tag')
                                        }
                                        parser.state = S.CLOSE_TAG_SAW_WHITE
                                    }
                                    continue

                                case S.CLOSE_TAG_SAW_WHITE:
                                    if (isWhitespace(c)) {
                                        continue
                                    }
                                    if (c === '>') {
                                        closeTag(parser)
                                    } else {
                                        strictFail(parser, 'Invalid characters in closing tag')
                                    }
                                    continue

                                case S.TEXT_ENTITY:
                                case S.ATTRIB_VALUE_ENTITY_Q:
                                case S.ATTRIB_VALUE_ENTITY_U:
                                    var returnState
                                    var buffer
                                    switch (parser.state) {
                                        case S.TEXT_ENTITY:
                                            returnState = S.TEXT
                                            buffer = 'textNode'
                                            break

                                        case S.ATTRIB_VALUE_ENTITY_Q:
                                            returnState = S.ATTRIB_VALUE_QUOTED
                                            buffer = 'attribValue'
                                            break

                                        case S.ATTRIB_VALUE_ENTITY_U:
                                            returnState = S.ATTRIB_VALUE_UNQUOTED
                                            buffer = 'attribValue'
                                            break
                                    }

                                    if (c === ';') {
                                        parser[buffer] += parseEntity(parser)
                                        parser.entity = ''
                                        parser.state = returnState
                                    } else if (isMatch(parser.entity.length ? entityBody : entityStart, c)) {
                                        parser.entity += c
                                    } else {
                                        strictFail(parser, 'Invalid character in entity name')
                                        parser[buffer] += '&' + parser.entity + c
                                        parser.entity = ''
                                        parser.state = returnState
                                    }

                                    continue

                                default:
                                    throw new Error(parser, 'Unknown state: ' + parser.state)
                            }
                        } // while

                        if (parser.position >= parser.bufferCheckPosition) {
                            checkBufferLength(parser)
                        }
                        return parser
                    }

                    /*! http://mths.be/fromcodepoint v0.1.0 by @mathias */
                    /* istanbul ignore next */
                    if (!String.fromCodePoint) {
                        (function() {
                            var stringFromCharCode = String.fromCharCode
                            var floor = Math.floor
                            var fromCodePoint = function() {
                                var MAX_SIZE = 0x4000
                                var codeUnits = []
                                var highSurrogate
                                var lowSurrogate
                                var index = -1
                                var length = arguments.length
                                if (!length) {
                                    return ''
                                }
                                var result = ''
                                while (++index < length) {
                                    var codePoint = Number(arguments[index])
                                    if (
                                        !isFinite(codePoint) || // `NaN`, `+Infinity`, or `-Infinity`
                                        codePoint < 0 || // not a valid Unicode code point
                                        codePoint > 0x10FFFF || // not a valid Unicode code point
                                        floor(codePoint) !== codePoint // not an integer
                                    ) {
                                        throw RangeError('Invalid code point: ' + codePoint)
                                    }
                                    if (codePoint <= 0xFFFF) { // BMP code point
                                        codeUnits.push(codePoint)
                                    } else { // Astral code point; split in surrogate halves
                                        // http://mathiasbynens.be/notes/javascript-encoding#surrogate-formulae
                                        codePoint -= 0x10000
                                        highSurrogate = (codePoint >> 10) + 0xD800
                                        lowSurrogate = (codePoint % 0x400) + 0xDC00
                                        codeUnits.push(highSurrogate, lowSurrogate)
                                    }
                                    if (index + 1 === length || codeUnits.length > MAX_SIZE) {
                                        result += stringFromCharCode.apply(null, codeUnits)
                                        codeUnits.length = 0
                                    }
                                }
                                return result
                            }
                            /* istanbul ignore next */
                            if (Object.defineProperty) {
                                Object.defineProperty(String, 'fromCodePoint', {
                                    value: fromCodePoint,
                                    configurable: true,
                                    writable: true
                                })
                            } else {
                                String.fromCodePoint = fromCodePoint
                            }
                        }())
                    }
                })(typeof exports === 'undefined' ? this.sax = {} : exports)

            }).call(this)
        }).call(this, require("buffer").Buffer)
    }, {
        "buffer": 3,
        "stream": 15,
        "string_decoder": 49
    }],
    64: [function(require, module, exports) {
        const {
            setTimeout
        } = require('timers');

        // A cache that expires.
        module.exports = class Cache extends Map {
            constructor(timeout = 1000) {
                super();
                this.timeout = timeout;
            }
            set(key, value) {
                if (this.has(key)) {
                    clearTimeout(super.get(key).tid);
                }
                super.set(key, {
                    tid: setTimeout(this.delete.bind(this, key), this.timeout).unref(),
                    value,
                });
            }
            get(key) {
                let entry = super.get(key);
                if (entry) {
                    return entry.value;
                }
                return null;
            }
            getOrSet(key, fn) {
                if (this.has(key)) {
                    return this.get(key);
                } else {
                    let value = fn();
                    this.set(key, value);
                    (async () => {
                        try {
                            await value;
                        } catch (err) {
                            this.delete(key);
                        }
                    })();
                    return value;
                }
            }
            delete(key) {
                let entry = super.get(key);
                if (entry) {
                    clearTimeout(entry.tid);
                    super.delete(key);
                }
            }
            clear() {
                for (let entry of this.values()) {
                    clearTimeout(entry.tid);
                }
                super.clear();
            }
        };

    }, {
        "timers": 50
    }],
    65: [function(require, module, exports) {
        const utils = require('./utils');
        const FORMATS = require('./formats');


        // Use these to help sort formats, higher index is better.
        const audioEncodingRanks = [
            'mp4a',
            'mp3',
            'vorbis',
            'aac',
            'opus',
            'flac',
        ];
        const videoEncodingRanks = [
            'mp4v',
            'avc1',
            'Sorenson H.283',
            'MPEG-4 Visual',
            'VP8',
            'VP9',
            'H.264',
        ];

        const getVideoBitrate = format => format.bitrate || 0;
        const getVideoEncodingRank = format =>
            videoEncodingRanks.findIndex(enc => format.codecs && format.codecs.includes(enc));
        const getAudioBitrate = format => format.audioBitrate || 0;
        const getAudioEncodingRank = format =>
            audioEncodingRanks.findIndex(enc => format.codecs && format.codecs.includes(enc));


        /**
         * Sort formats by a list of functions.
         *
         * @param {Object} a
         * @param {Object} b
         * @param {Array.<Function>} sortBy
         * @returns {number}
         */
        const sortFormatsBy = (a, b, sortBy) => {
            let res = 0;
            for (let fn of sortBy) {
                res = fn(b) - fn(a);
                if (res !== 0) {
                    break;
                }
            }
            return res;
        };


        const sortFormatsByVideo = (a, b) => sortFormatsBy(a, b, [
            format => parseInt(format.qualityLabel),
            getVideoBitrate,
            getVideoEncodingRank,
        ]);


        const sortFormatsByAudio = (a, b) => sortFormatsBy(a, b, [
            getAudioBitrate,
            getAudioEncodingRank,
        ]);


        /**
         * Sort formats from highest quality to lowest.
         *
         * @param {Object} a
         * @param {Object} b
         * @returns {number}
         */
        exports.sortFormats = (a, b) => sortFormatsBy(a, b, [
            // Formats with both video and audio are ranked highest.
            format => +!!format.isHLS,
            format => +!!format.isDashMPD,
            format => +(format.contentLength > 0),
            format => +(format.hasVideo && format.hasAudio),
            format => +format.hasVideo,
            format => parseInt(format.qualityLabel) || 0,
            getVideoBitrate,
            getAudioBitrate,
            getVideoEncodingRank,
            getAudioEncodingRank,
        ]);


        /**
         * Choose a format depending on the given options.
         *
         * @param {Array.<Object>} formats
         * @param {Object} options
         * @returns {Object}
         * @throws {Error} when no format matches the filter/format rules
         */
        exports.chooseFormat = (formats, options) => {
            if (typeof options.format === 'object') {
                if (!options.format.url) {
                    throw Error('Invalid format given, did you use `ytdl.getInfo()`?');
                }
                return options.format;
            }

            if (options.filter) {
                formats = exports.filterFormats(formats, options.filter);
            }

            // We currently only support HLS-Formats for livestreams
            // So we (now) remove all non-HLS streams
            if (formats.some(fmt => fmt.isHLS)) {
                formats = formats.filter(fmt => fmt.isHLS || !fmt.isLive);
            }

            let format;
            const quality = options.quality || 'highest';
            switch (quality) {
                case 'highest':
                    format = formats[0];
                    break;

                case 'lowest':
                    format = formats[formats.length - 1];
                    break;

                case 'highestaudio': {
                    formats = exports.filterFormats(formats, 'audio');
                    formats.sort(sortFormatsByAudio);
                    // Filter for only the best audio format
                    const bestAudioFormat = formats[0];
                    formats = formats.filter(f => sortFormatsByAudio(bestAudioFormat, f) === 0);
                    // Check for the worst video quality for the best audio quality and pick according
                    // This does not loose default sorting of video encoding and bitrate
                    const worstVideoQuality = formats.map(f => parseInt(f.qualityLabel) || 0).sort((a, b) => a - b)[0];
                    format = formats.find(f => (parseInt(f.qualityLabel) || 0) === worstVideoQuality);
                    break;
                }

                case 'lowestaudio':
                    formats = exports.filterFormats(formats, 'audio');
                    formats.sort(sortFormatsByAudio);
                    format = formats[formats.length - 1];
                    break;

                case 'highestvideo': {
                    formats = exports.filterFormats(formats, 'video');
                    formats.sort(sortFormatsByVideo);
                    // Filter for only the best video format
                    const bestVideoFormat = formats[0];
                    formats = formats.filter(f => sortFormatsByVideo(bestVideoFormat, f) === 0);
                    // Check for the worst audio quality for the best video quality and pick according
                    // This does not loose default sorting of audio encoding and bitrate
                    const worstAudioQuality = formats.map(f => f.audioBitrate || 0).sort((a, b) => a - b)[0];
                    format = formats.find(f => (f.audioBitrate || 0) === worstAudioQuality);
                    break;
                }

                case 'lowestvideo':
                    formats = exports.filterFormats(formats, 'video');
                    formats.sort(sortFormatsByVideo);
                    format = formats[formats.length - 1];
                    break;

                default:
                    format = getFormatByQuality(quality, formats);
                    break;
            }

            if (!format) {
                throw Error(`No such format found: ${quality}`);
            }
            return format;
        };

        /**
         * Gets a format based on quality or array of quality's
         *
         * @param {string|[string]} quality
         * @param {[Object]} formats
         * @returns {Object}
         */
        const getFormatByQuality = (quality, formats) => {
            let getFormat = itag => formats.find(format => `${format.itag}` === `${itag}`);
            if (Array.isArray(quality)) {
                return getFormat(quality.find(q => getFormat(q)));
            } else {
                return getFormat(quality);
            }
        };


        /**
         * @param {Array.<Object>} formats
         * @param {Function} filter
         * @returns {Array.<Object>}
         */
        exports.filterFormats = (formats, filter) => {
            let fn;
            switch (filter) {
                case 'videoandaudio':
                case 'audioandvideo':
                    fn = format => format.hasVideo && format.hasAudio;
                    break;

                case 'video':
                    fn = format => format.hasVideo;
                    break;

                case 'videoonly':
                    fn = format => format.hasVideo && !format.hasAudio;
                    break;

                case 'audio':
                    fn = format => format.hasAudio;
                    break;

                case 'audioonly':
                    fn = format => !format.hasVideo && format.hasAudio;
                    break;

                default:
                    if (typeof filter === 'function') {
                        fn = filter;
                    } else {
                        throw TypeError(`Given filter (${filter}) is not supported`);
                    }
            }
            return formats.filter(format => !!format.url && fn(format));
        };


        /**
         * @param {Object} format
         * @returns {Object}
         */
        exports.addFormatMeta = format => {
            format = Object.assign({}, FORMATS[format.itag], format);
            format.hasVideo = !!format.qualityLabel;
            format.hasAudio = !!format.audioBitrate;
            format.container = format.mimeType ?
                format.mimeType.split(';')[0].split('/')[1] : null;
            format.codecs = format.mimeType ?
                utils.between(format.mimeType, 'codecs="', '"') : null;
            format.videoCodec = format.hasVideo && format.codecs ?
                format.codecs.split(', ')[0] : null;
            format.audioCodec = format.hasAudio && format.codecs ?
                format.codecs.split(', ').slice(-1)[0] : null;
            format.isLive = /\bsource[/=]yt_live_broadcast\b/.test(format.url);
            format.isHLS = /\/manifest\/hls_(variant|playlist)\//.test(format.url);
            format.isDashMPD = /\/manifest\/dash\//.test(format.url);
            return format;
        };

    }, {
        "./formats": 66,
        "./utils": 72
    }],
    66: [function(require, module, exports) {
        /**
         * http://en.wikipedia.org/wiki/YouTube#Quality_and_formats
         */
        module.exports = {

            5: {
                mimeType: 'video/flv; codecs="Sorenson H.283, mp3"',
                qualityLabel: '240p',
                bitrate: 250000,
                audioBitrate: 64,
            },

            6: {
                mimeType: 'video/flv; codecs="Sorenson H.263, mp3"',
                qualityLabel: '270p',
                bitrate: 800000,
                audioBitrate: 64,
            },

            13: {
                mimeType: 'video/3gp; codecs="MPEG-4 Visual, aac"',
                qualityLabel: null,
                bitrate: 500000,
                audioBitrate: null,
            },

            17: {
                mimeType: 'video/3gp; codecs="MPEG-4 Visual, aac"',
                qualityLabel: '144p',
                bitrate: 50000,
                audioBitrate: 24,
            },

            18: {
                mimeType: 'video/mp4; codecs="H.264, aac"',
                qualityLabel: '360p',
                bitrate: 500000,
                audioBitrate: 96,
            },

            22: {
                mimeType: 'video/mp4; codecs="H.264, aac"',
                qualityLabel: '720p',
                bitrate: 2000000,
                audioBitrate: 192,
            },

            34: {
                mimeType: 'video/flv; codecs="H.264, aac"',
                qualityLabel: '360p',
                bitrate: 500000,
                audioBitrate: 128,
            },

            35: {
                mimeType: 'video/flv; codecs="H.264, aac"',
                qualityLabel: '480p',
                bitrate: 800000,
                audioBitrate: 128,
            },

            36: {
                mimeType: 'video/3gp; codecs="MPEG-4 Visual, aac"',
                qualityLabel: '240p',
                bitrate: 175000,
                audioBitrate: 32,
            },

            37: {
                mimeType: 'video/mp4; codecs="H.264, aac"',
                qualityLabel: '1080p',
                bitrate: 3000000,
                audioBitrate: 192,
            },

            38: {
                mimeType: 'video/mp4; codecs="H.264, aac"',
                qualityLabel: '3072p',
                bitrate: 3500000,
                audioBitrate: 192,
            },

            43: {
                mimeType: 'video/webm; codecs="VP8, vorbis"',
                qualityLabel: '360p',
                bitrate: 500000,
                audioBitrate: 128,
            },

            44: {
                mimeType: 'video/webm; codecs="VP8, vorbis"',
                qualityLabel: '480p',
                bitrate: 1000000,
                audioBitrate: 128,
            },

            45: {
                mimeType: 'video/webm; codecs="VP8, vorbis"',
                qualityLabel: '720p',
                bitrate: 2000000,
                audioBitrate: 192,
            },

            46: {
                mimeType: 'audio/webm; codecs="vp8, vorbis"',
                qualityLabel: '1080p',
                bitrate: null,
                audioBitrate: 192,
            },

            82: {
                mimeType: 'video/mp4; codecs="H.264, aac"',
                qualityLabel: '360p',
                bitrate: 500000,
                audioBitrate: 96,
            },

            83: {
                mimeType: 'video/mp4; codecs="H.264, aac"',
                qualityLabel: '240p',
                bitrate: 500000,
                audioBitrate: 96,
            },

            84: {
                mimeType: 'video/mp4; codecs="H.264, aac"',
                qualityLabel: '720p',
                bitrate: 2000000,
                audioBitrate: 192,
            },

            85: {
                mimeType: 'video/mp4; codecs="H.264, aac"',
                qualityLabel: '1080p',
                bitrate: 3000000,
                audioBitrate: 192,
            },

            91: {
                mimeType: 'video/ts; codecs="H.264, aac"',
                qualityLabel: '144p',
                bitrate: 100000,
                audioBitrate: 48,
            },

            92: {
                mimeType: 'video/ts; codecs="H.264, aac"',
                qualityLabel: '240p',
                bitrate: 150000,
                audioBitrate: 48,
            },

            93: {
                mimeType: 'video/ts; codecs="H.264, aac"',
                qualityLabel: '360p',
                bitrate: 500000,
                audioBitrate: 128,
            },

            94: {
                mimeType: 'video/ts; codecs="H.264, aac"',
                qualityLabel: '480p',
                bitrate: 800000,
                audioBitrate: 128,
            },

            95: {
                mimeType: 'video/ts; codecs="H.264, aac"',
                qualityLabel: '720p',
                bitrate: 1500000,
                audioBitrate: 256,
            },

            96: {
                mimeType: 'video/ts; codecs="H.264, aac"',
                qualityLabel: '1080p',
                bitrate: 2500000,
                audioBitrate: 256,
            },

            100: {
                mimeType: 'audio/webm; codecs="VP8, vorbis"',
                qualityLabel: '360p',
                bitrate: null,
                audioBitrate: 128,
            },

            101: {
                mimeType: 'audio/webm; codecs="VP8, vorbis"',
                qualityLabel: '360p',
                bitrate: null,
                audioBitrate: 192,
            },

            102: {
                mimeType: 'audio/webm; codecs="VP8, vorbis"',
                qualityLabel: '720p',
                bitrate: null,
                audioBitrate: 192,
            },

            120: {
                mimeType: 'video/flv; codecs="H.264, aac"',
                qualityLabel: '720p',
                bitrate: 2000000,
                audioBitrate: 128,
            },

            127: {
                mimeType: 'audio/ts; codecs="aac"',
                qualityLabel: null,
                bitrate: null,
                audioBitrate: 96,
            },

            128: {
                mimeType: 'audio/ts; codecs="aac"',
                qualityLabel: null,
                bitrate: null,
                audioBitrate: 96,
            },

            132: {
                mimeType: 'video/ts; codecs="H.264, aac"',
                qualityLabel: '240p',
                bitrate: 150000,
                audioBitrate: 48,
            },

            133: {
                mimeType: 'video/mp4; codecs="H.264"',
                qualityLabel: '240p',
                bitrate: 200000,
                audioBitrate: null,
            },

            134: {
                mimeType: 'video/mp4; codecs="H.264"',
                qualityLabel: '360p',
                bitrate: 300000,
                audioBitrate: null,
            },

            135: {
                mimeType: 'video/mp4; codecs="H.264"',
                qualityLabel: '480p',
                bitrate: 500000,
                audioBitrate: null,
            },

            136: {
                mimeType: 'video/mp4; codecs="H.264"',
                qualityLabel: '720p',
                bitrate: 1000000,
                audioBitrate: null,
            },

            137: {
                mimeType: 'video/mp4; codecs="H.264"',
                qualityLabel: '1080p',
                bitrate: 2500000,
                audioBitrate: null,
            },

            138: {
                mimeType: 'video/mp4; codecs="H.264"',
                qualityLabel: '4320p',
                bitrate: 13500000,
                audioBitrate: null,
            },

            139: {
                mimeType: 'audio/mp4; codecs="aac"',
                qualityLabel: null,
                bitrate: null,
                audioBitrate: 48,
            },

            140: {
                mimeType: 'audio/m4a; codecs="aac"',
                qualityLabel: null,
                bitrate: null,
                audioBitrate: 128,
            },

            141: {
                mimeType: 'audio/mp4; codecs="aac"',
                qualityLabel: null,
                bitrate: null,
                audioBitrate: 256,
            },

            151: {
                mimeType: 'video/ts; codecs="H.264, aac"',
                qualityLabel: '720p',
                bitrate: 50000,
                audioBitrate: 24,
            },

            160: {
                mimeType: 'video/mp4; codecs="H.264"',
                qualityLabel: '144p',
                bitrate: 100000,
                audioBitrate: null,
            },

            171: {
                mimeType: 'audio/webm; codecs="vorbis"',
                qualityLabel: null,
                bitrate: null,
                audioBitrate: 128,
            },

            172: {
                mimeType: 'audio/webm; codecs="vorbis"',
                qualityLabel: null,
                bitrate: null,
                audioBitrate: 192,
            },

            242: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: '240p',
                bitrate: 100000,
                audioBitrate: null,
            },

            243: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: '360p',
                bitrate: 250000,
                audioBitrate: null,
            },

            244: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: '480p',
                bitrate: 500000,
                audioBitrate: null,
            },

            247: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: '720p',
                bitrate: 700000,
                audioBitrate: null,
            },

            248: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: '1080p',
                bitrate: 1500000,
                audioBitrate: null,
            },

            249: {
                mimeType: 'audio/webm; codecs="opus"',
                qualityLabel: null,
                bitrate: null,
                audioBitrate: 48,
            },

            250: {
                mimeType: 'audio/webm; codecs="opus"',
                qualityLabel: null,
                bitrate: null,
                audioBitrate: 64,
            },

            251: {
                mimeType: 'audio/webm; codecs="opus"',
                qualityLabel: null,
                bitrate: null,
                audioBitrate: 160,
            },

            264: {
                mimeType: 'video/mp4; codecs="H.264"',
                qualityLabel: '1440p',
                bitrate: 4000000,
                audioBitrate: null,
            },

            266: {
                mimeType: 'video/mp4; codecs="H.264"',
                qualityLabel: '2160p',
                bitrate: 12500000,
                audioBitrate: null,
            },

            271: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: '1440p',
                bitrate: 9000000,
                audioBitrate: null,
            },

            272: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: '4320p',
                bitrate: 20000000,
                audioBitrate: null,
            },

            278: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: '144p 30fps',
                bitrate: 80000,
                audioBitrate: null,
            },

            298: {
                mimeType: 'video/mp4; codecs="H.264"',
                qualityLabel: '720p',
                bitrate: 3000000,
                audioBitrate: null,
            },

            299: {
                mimeType: 'video/mp4; codecs="H.264"',
                qualityLabel: '1080p',
                bitrate: 5500000,
                audioBitrate: null,
            },

            300: {
                mimeType: 'video/ts; codecs="H.264, aac"',
                qualityLabel: '720p',
                bitrate: 1318000,
                audioBitrate: 48,
            },

            302: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: '720p HFR',
                bitrate: 2500000,
                audioBitrate: null,
            },

            303: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: '1080p HFR',
                bitrate: 5000000,
                audioBitrate: null,
            },

            308: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: '1440p HFR',
                bitrate: 10000000,
                audioBitrate: null,
            },

            313: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: '2160p',
                bitrate: 13000000,
                audioBitrate: null,
            },

            315: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: '2160p HFR',
                bitrate: 20000000,
                audioBitrate: null,
            },

            330: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: '144p HDR, HFR',
                bitrate: 80000,
                audioBitrate: null,
            },

            331: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: '240p HDR, HFR',
                bitrate: 100000,
                audioBitrate: null,
            },

            332: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: '360p HDR, HFR',
                bitrate: 250000,
                audioBitrate: null,
            },

            333: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: '240p HDR, HFR',
                bitrate: 500000,
                audioBitrate: null,
            },

            334: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: '720p HDR, HFR',
                bitrate: 1000000,
                audioBitrate: null,
            },

            335: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: '1080p HDR, HFR',
                bitrate: 1500000,
                audioBitrate: null,
            },

            336: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: '1440p HDR, HFR',
                bitrate: 5000000,
                audioBitrate: null,
            },

            337: {
                mimeType: 'video/webm; codecs="VP9"',
                qualityLabel: '2160p HDR, HFR',
                bitrate: 12000000,
                audioBitrate: null,
            },

        };

    }, {}],
    67: [function(require, module, exports) {
        (function(setImmediate) {
            (function() {
                const PassThrough = require('stream').PassThrough;
                const getInfo = require('./info');
                const utils = require('./utils');
                const formatUtils = require('./format-utils');
                const urlUtils = require('./url-utils');
                const sig = require('./sig');
                const miniget = require('miniget');
                const m3u8stream = require('m3u8stream');
                const {
                    parseTimestamp
                } = require('m3u8stream');


                /**
                 * @param {string} link
                 * @param {!Object} options
                 * @returns {ReadableStream}
                 */
                const ytdl = (link, options) => {
                    const stream = createStream(options);
                    ytdl.getInfo(link, options).then(info => {
                        downloadFromInfoCallback(stream, info, options);
                    }, stream.emit.bind(stream, 'error'));
                    return stream;
                };
                Exported.ytdl = ytdl;
                module.exports = ytdl;

                ytdl.getBasicInfo = getInfo.getBasicInfo;
                ytdl.getInfo = getInfo.getInfo;
                ytdl.chooseFormat = formatUtils.chooseFormat;
                ytdl.filterFormats = formatUtils.filterFormats;
                ytdl.validateID = urlUtils.validateID;
                ytdl.validateURL = urlUtils.validateURL;
                ytdl.getURLVideoID = urlUtils.getURLVideoID;
                ytdl.getVideoID = urlUtils.getVideoID;
                ytdl.cache = {
                    sig: sig.cache,
                    info: getInfo.cache,
                    watch: getInfo.watchPageCache,
                    cookie: getInfo.cookieCache,
                };
                ytdl.version = require('../package.json').version;


                const createStream = options => {
                    const stream = new PassThrough({
                        highWaterMark: (options && options.highWaterMark) || 1024 * 512,
                    });
                    stream._destroy = () => {
                        stream.destroyed = true;
                    };
                    return stream;
                };


                const pipeAndSetEvents = (req, stream, end) => {
                    // Forward events from the request to the stream.
                    [
                        'abort', 'request', 'response', 'error', 'redirect', 'retry', 'reconnect',
                    ].forEach(event => {
                        req.prependListener(event, stream.emit.bind(stream, event));
                    });
                    req.pipe(stream, {
                        end
                    });
                };


                /**
                 * Chooses a format to download.
                 *
                 * @param {stream.Readable} stream
                 * @param {Object} info
                 * @param {Object} options
                 */
                const downloadFromInfoCallback = (stream, info, options) => {
                    options = options || {};

                    let err = utils.playError(info.player_response, ['UNPLAYABLE', 'LIVE_STREAM_OFFLINE', 'LOGIN_REQUIRED']);
                    if (err) {
                        stream.emit('error', err);
                        return;
                    }

                    if (!info.formats.length) {
                        stream.emit('error', Error('This video is unavailable'));
                        return;
                    }

                    let format;
                    try {
                        format = formatUtils.chooseFormat(info.formats, options);
                    } catch (e) {
                        stream.emit('error', e);
                        return;
                    }
                    stream.emit('info', info, format);
                    if (stream.destroyed) {
                        return;
                    }

                    let contentLength, downloaded = 0;
                    const ondata = chunk => {
                        downloaded += chunk.length;
                        stream.emit('progress', chunk.length, downloaded, contentLength);
                    };

                    if (options.IPv6Block) {
                        options.requestOptions = Object.assign({}, options.requestOptions, {
                            family: 6,
                            localAddress: utils.getRandomIPv6(options.IPv6Block),
                        });
                    }

                    // Download the file in chunks, in this case the default is 10MB,
                    // anything over this will cause youtube to throttle the download
                    const dlChunkSize = options.dlChunkSize || 1024 * 1024 * 10;
                    let req;
                    let shouldEnd = true;

                    if (format.isHLS || format.isDashMPD) {
                        req = m3u8stream(format.url, {
                            chunkReadahead: +info.live_chunk_readahead,
                            begin: options.begin || (format.isLive && Date.now()),
                            liveBuffer: options.liveBuffer,
                            requestOptions: options.requestOptions,
                            parser: format.isDashMPD ? 'dash-mpd' : 'm3u8',
                            id: format.itag,
                        });

                        req.on('progress', (segment, totalSegments) => {
                            stream.emit('progress', segment.size, segment.num, totalSegments);
                        });
                        pipeAndSetEvents(req, stream, shouldEnd);
                    } else {
                        const requestOptions = Object.assign({}, options.requestOptions, {
                            maxReconnects: 6,
                            maxRetries: 3,
                            backoff: {
                                inc: 500,
                                max: 10000
                            },
                        });

                        let shouldBeChunked = dlChunkSize !== 0 && (!format.hasAudio || !format.hasVideo);

                        if (shouldBeChunked) {
                            let start = (options.range && options.range.start) || 0;
                            let end = start + dlChunkSize;
                            const rangeEnd = options.range && options.range.end;

                            contentLength = options.range ?
                                (rangeEnd ? rangeEnd + 1 : parseInt(format.contentLength)) - start :
                                parseInt(format.contentLength);

                            const getNextChunk = () => {
                                if (!rangeEnd && end >= contentLength) end = 0;
                                if (rangeEnd && end > rangeEnd) end = rangeEnd;
                                shouldEnd = !end || end === rangeEnd;

                                requestOptions.headers = Object.assign({}, requestOptions.headers, {
                                    Range: `bytes=${start}-${end || ''}`,
                                });

                                req = miniget(format.url, requestOptions);
                                req.on('data', ondata);
                                req.on('end', () => {
                                    if (stream.destroyed) {
                                        return;
                                    }
                                    if (end && end !== rangeEnd) {
                                        start = end + 1;
                                        end += dlChunkSize;
                                        getNextChunk();
                                    }
                                });
                                pipeAndSetEvents(req, stream, shouldEnd);
                            };
                            getNextChunk();
                        } else {
                            // Audio only and video only formats don't support begin
                            if (options.begin) {
                                format.url += `&begin=${parseTimestamp(options.begin)}`;
                            }
                            if (options.range && (options.range.start || options.range.end)) {
                                requestOptions.headers = Object.assign({}, requestOptions.headers, {
                                    Range: `bytes=${options.range.start || '0'}-${options.range.end || ''}`,
                                });
                            }
                            req = miniget(format.url, requestOptions);
                            req.on('response', res => {
                                if (stream.destroyed) {
                                    return;
                                }
                                contentLength = contentLength || parseInt(res.headers['content-length']);
                            });
                            req.on('data', ondata);
                            pipeAndSetEvents(req, stream, shouldEnd);
                        }
                    }

                    stream._destroy = () => {
                        stream.destroyed = true;
                        req.destroy();
                        req.end();
                    };
                };


                /**
                 * Can be used to download video after its `info` is gotten through
                 * `ytdl.getInfo()`. In case the user might want to look at the
                 * `info` object before deciding to download.
                 *
                 * @param {Object} info
                 * @param {!Object} options
                 * @returns {ReadableStream}
                 */
                ytdl.downloadFromInfo = (info, options) => {
                    const stream = createStream(options);
                    if (!info.full) {
                        throw Error('Cannot use `ytdl.downloadFromInfo()` when called ' +
                            'with info from `ytdl.getBasicInfo()`');
                    }
                    setImmediate(() => {
                        downloadFromInfoCallback(stream, info, options);
                    });
                    return stream;
                };

            }).call(this)
        }).call(this, require("timers").setImmediate)
    }, {
        "../package.json": 73,
        "./format-utils": 65,
        "./info": 69,
        "./sig": 70,
        "./url-utils": 71,
        "./utils": 72,
        "m3u8stream": 58,
        "miniget": 62,
        "stream": 15,
        "timers": 50
    }],
    68: [function(require, module, exports) {
        const utils = require('./utils');
        const qs = require('querystring');
        const {
            parseTimestamp
        } = require('m3u8stream');


        const BASE_URL = 'https://www.youtube.com/watch?v=';
        const TITLE_TO_CATEGORY = {
            song: {
                name: 'Music',
                url: 'https://music.youtube.com/'
            },
        };

        const getText = obj => obj ? obj.runs ? obj.runs[0].text : obj.simpleText : null;


        /**
         * Get video media.
         *
         * @param {Object} info
         * @returns {Object}
         */
        exports.getMedia = info => {
            let media = {};
            let results = [];
            try {
                results = info.response.contents.twoColumnWatchNextResults.results.results.contents;
            } catch (err) {
                // Do nothing
            }

            let result = results.find(v => v.videoSecondaryInfoRenderer);
            if (!result) {
                return {};
            }

            try {
                let metadataRows =
                    (result.metadataRowContainer || result.videoSecondaryInfoRenderer.metadataRowContainer)
                    .metadataRowContainerRenderer.rows;
                for (let row of metadataRows) {
                    if (row.metadataRowRenderer) {
                        let title = getText(row.metadataRowRenderer.title).toLowerCase();
                        let contents = row.metadataRowRenderer.contents[0];
                        media[title] = getText(contents);
                        let runs = contents.runs;
                        if (runs && runs[0].navigationEndpoint) {
                            media[`${title}_url`] = new URL(
                                runs[0].navigationEndpoint.commandMetadata.webCommandMetadata.url, BASE_URL).toString();
                        }
                        if (title in TITLE_TO_CATEGORY) {
                            media.category = TITLE_TO_CATEGORY[title].name;
                            media.category_url = TITLE_TO_CATEGORY[title].url;
                        }
                    } else if (row.richMetadataRowRenderer) {
                        let contents = row.richMetadataRowRenderer.contents;
                        let boxArt = contents
                            .filter(meta => meta.richMetadataRenderer.style === 'RICH_METADATA_RENDERER_STYLE_BOX_ART');
                        for (let {
                                richMetadataRenderer
                            }
                            of boxArt) {
                            let meta = richMetadataRenderer;
                            media.year = getText(meta.subtitle);
                            let type = getText(meta.callToAction).split(' ')[1];
                            media[type] = getText(meta.title);
                            media[`${type}_url`] = new URL(
                                meta.endpoint.commandMetadata.webCommandMetadata.url, BASE_URL).toString();
                            media.thumbnails = meta.thumbnail.thumbnails;
                        }
                        let topic = contents
                            .filter(meta => meta.richMetadataRenderer.style === 'RICH_METADATA_RENDERER_STYLE_TOPIC');
                        for (let {
                                richMetadataRenderer
                            }
                            of topic) {
                            let meta = richMetadataRenderer;
                            media.category = getText(meta.title);
                            media.category_url = new URL(
                                meta.endpoint.commandMetadata.webCommandMetadata.url, BASE_URL).toString();
                        }
                    }
                }
            } catch (err) {
                // Do nothing.
            }

            return media;
        };


        const isVerified = badges => !!(badges && badges.find(b => b.metadataBadgeRenderer.tooltip === 'Verified'));


        /**
         * Get video author.
         *
         * @param {Object} info
         * @returns {Object}
         */
        exports.getAuthor = info => {
            let channelId, thumbnails = [],
                subscriberCount, verified = false;
            try {
                let results = info.response.contents.twoColumnWatchNextResults.results.results.contents;
                let v = results.find(v2 =>
                    v2.videoSecondaryInfoRenderer &&
                    v2.videoSecondaryInfoRenderer.owner &&
                    v2.videoSecondaryInfoRenderer.owner.videoOwnerRenderer);
                let videoOwnerRenderer = v.videoSecondaryInfoRenderer.owner.videoOwnerRenderer;
                channelId = videoOwnerRenderer.navigationEndpoint.browseEndpoint.browseId;
                thumbnails = videoOwnerRenderer.thumbnail.thumbnails.map(thumbnail => {
                    thumbnail.url = new URL(thumbnail.url, BASE_URL).toString();
                    return thumbnail;
                });
                subscriberCount = utils.parseAbbreviatedNumber(getText(videoOwnerRenderer.subscriberCountText));
                verified = isVerified(videoOwnerRenderer.badges);
            } catch (err) {
                // Do nothing.
            }
            try {
                let videoDetails = info.player_response.microformat && info.player_response.microformat.playerMicroformatRenderer;
                let id = (videoDetails && videoDetails.channelId) || channelId || info.player_response.videoDetails.channelId;
                let author = {
                    id: id,
                    name: videoDetails ? videoDetails.ownerChannelName : info.player_response.videoDetails.author,
                    user: videoDetails ? videoDetails.ownerProfileUrl.split('/').slice(-1)[0] : null,
                    channel_url: `https://www.youtube.com/channel/${id}`,
                    external_channel_url: videoDetails ? `https://www.youtube.com/channel/${videoDetails.externalChannelId}` : '',
                    user_url: videoDetails ? new URL(videoDetails.ownerProfileUrl, BASE_URL).toString() : '',
                    thumbnails,
                    verified,
                    subscriber_count: subscriberCount,
                };
                if (thumbnails.length) {
                    utils.deprecate(author, 'avatar', author.thumbnails[0].url, 'author.avatar', 'author.thumbnails[0].url');
                }
                return author;
            } catch (err) {
                return {};
            }
        };

        const parseRelatedVideo = (details, rvsParams) => {
            if (!details) return;
            try {
                let viewCount = getText(details.viewCountText);
                let shortViewCount = getText(details.shortViewCountText);
                let rvsDetails = rvsParams.find(elem => elem.id === details.videoId);
                if (!/^\d/.test(shortViewCount)) {
                    shortViewCount = (rvsDetails && rvsDetails.short_view_count_text) || '';
                }
                viewCount = (/^\d/.test(viewCount) ? viewCount : shortViewCount).split(' ')[0];
                let browseEndpoint = details.shortBylineText.runs[0].navigationEndpoint.browseEndpoint;
                let channelId = browseEndpoint.browseId;
                let name = getText(details.shortBylineText);
                let user = (browseEndpoint.canonicalBaseUrl || '').split('/').slice(-1)[0];
                let video = {
                    id: details.videoId,
                    title: getText(details.title),
                    published: getText(details.publishedTimeText),
                    author: {
                        id: channelId,
                        name,
                        user,
                        channel_url: `https://www.youtube.com/channel/${channelId}`,
                        user_url: `https://www.youtube.com/user/${user}`,
                        thumbnails: details.channelThumbnail.thumbnails.map(thumbnail => {
                            thumbnail.url = new URL(thumbnail.url, BASE_URL).toString();
                            return thumbnail;
                        }),
                        verified: isVerified(details.ownerBadges),

                        [Symbol.toPrimitive]() {
                            console.warn(`\`relatedVideo.author\` will be removed in a near future release, ` +
                                `use \`relatedVideo.author.name\` instead.`);
                            return video.author.name;
                        },

                    },
                    short_view_count_text: shortViewCount.split(' ')[0],
                    view_count: viewCount.replace(/,/g, ''),
                    length_seconds: details.lengthText ?
                        Math.floor(parseTimestamp(getText(details.lengthText)) / 1000) : rvsParams && `${rvsParams.length_seconds}`,
                    thumbnails: details.thumbnail.thumbnails,
                    richThumbnails: details.richThumbnail ?
                        details.richThumbnail.movingThumbnailRenderer.movingThumbnailDetails.thumbnails : [],
                    isLive: !!(details.badges && details.badges.find(b => b.metadataBadgeRenderer.label === 'LIVE NOW')),
                };

                utils.deprecate(video, 'author_thumbnail', video.author.thumbnails[0].url,
                    'relatedVideo.author_thumbnail', 'relatedVideo.author.thumbnails[0].url');
                utils.deprecate(video, 'ucid', video.author.id, 'relatedVideo.ucid', 'relatedVideo.author.id');
                utils.deprecate(video, 'video_thumbnail', video.thumbnails[0].url,
                    'relatedVideo.video_thumbnail', 'relatedVideo.thumbnails[0].url');
                return video;
            } catch (err) {
                // Skip.
            }
        };

        /**
         * Get related videos.
         *
         * @param {Object} info
         * @returns {Array.<Object>}
         */
        exports.getRelatedVideos = info => {
            let rvsParams = [],
                secondaryResults = [];
            try {
                rvsParams = info.response.webWatchNextResponseExtensionData.relatedVideoArgs.split(',').map(e => qs.parse(e));
            } catch (err) {
                // Do nothing.
            }
            try {
                secondaryResults = info.response.contents.twoColumnWatchNextResults.secondaryResults.secondaryResults.results;
            } catch (err) {
                return [];
            }
            let videos = [];
            for (let result of secondaryResults || []) {
                let details = result.compactVideoRenderer;
                if (details) {
                    let video = parseRelatedVideo(details, rvsParams);
                    if (video) videos.push(video);
                } else {
                    let autoplay = result.compactAutoplayRenderer || result.itemSectionRenderer;
                    if (!autoplay || !Array.isArray(autoplay.contents)) continue;
                    for (let content of autoplay.contents) {
                        let video = parseRelatedVideo(content.compactVideoRenderer, rvsParams);
                        if (video) videos.push(video);
                    }
                }
            }
            return videos;
        };

        /**
         * Get like count.
         *
         * @param {Object} info
         * @returns {number}
         */
        exports.getLikes = info => {
            try {
                let contents = info.response.contents.twoColumnWatchNextResults.results.results.contents;
                let video = contents.find(r => r.videoPrimaryInfoRenderer);
                let buttons = video.videoPrimaryInfoRenderer.videoActions.menuRenderer.topLevelButtons;
                let like = buttons.find(b => b.toggleButtonRenderer &&
                    b.toggleButtonRenderer.defaultIcon.iconType === 'LIKE');
                return parseInt(like.toggleButtonRenderer.defaultText.accessibility.accessibilityData.label.replace(/\D+/g, ''));
            } catch (err) {
                return null;
            }
        };

        /**
         * Get dislike count.
         *
         * @param {Object} info
         * @returns {number}
         */
        exports.getDislikes = info => {
            try {
                let contents = info.response.contents.twoColumnWatchNextResults.results.results.contents;
                let video = contents.find(r => r.videoPrimaryInfoRenderer);
                let buttons = video.videoPrimaryInfoRenderer.videoActions.menuRenderer.topLevelButtons;
                let dislike = buttons.find(b => b.toggleButtonRenderer &&
                    b.toggleButtonRenderer.defaultIcon.iconType === 'DISLIKE');
                return parseInt(dislike.toggleButtonRenderer.defaultText.accessibility.accessibilityData.label.replace(/\D+/g, ''));
            } catch (err) {
                return null;
            }
        };

        /**
         * Cleans up a few fields on `videoDetails`.
         *
         * @param {Object} videoDetails
         * @param {Object} info
         * @returns {Object}
         */
        exports.cleanVideoDetails = (videoDetails, info) => {
            videoDetails.thumbnails = videoDetails.thumbnail.thumbnails;
            delete videoDetails.thumbnail;
            utils.deprecate(videoDetails, 'thumbnail', {
                    thumbnails: videoDetails.thumbnails
                },
                'videoDetails.thumbnail.thumbnails', 'videoDetails.thumbnails');
            videoDetails.description = videoDetails.shortDescription || getText(videoDetails.description);
            delete videoDetails.shortDescription;
            utils.deprecate(videoDetails, 'shortDescription', videoDetails.description,
                'videoDetails.shortDescription', 'videoDetails.description');

            // Use more reliable `lengthSeconds` from `playerMicroformatRenderer`.
            videoDetails.lengthSeconds =
                (info.player_response.microformat &&
                    info.player_response.microformat.playerMicroformatRenderer.lengthSeconds) ||
                info.player_response.videoDetails.lengthSeconds;
            return videoDetails;
        };

        /**
         * Get storyboards info.
         *
         * @param {Object} info
         * @returns {Array.<Object>}
         */
        exports.getStoryboards = info => {
            const parts = info.player_response.storyboards &&
                info.player_response.storyboards.playerStoryboardSpecRenderer &&
                info.player_response.storyboards.playerStoryboardSpecRenderer.spec &&
                info.player_response.storyboards.playerStoryboardSpecRenderer.spec.split('|');

            if (!parts) return [];

            const url = new URL(parts.shift());

            return parts.map((part, i) => {
                let [
                    thumbnailWidth,
                    thumbnailHeight,
                    thumbnailCount,
                    columns,
                    rows,
                    interval,
                    nameReplacement,
                    sigh,
                ] = part.split('#');

                url.searchParams.set('sigh', sigh);

                thumbnailCount = parseInt(thumbnailCount, 10);
                columns = parseInt(columns, 10);
                rows = parseInt(rows, 10);

                const storyboardCount = Math.ceil(thumbnailCount / (columns * rows));

                return {
                    templateUrl: url.toString().replace('$L', i).replace('$N', nameReplacement),
                    thumbnailWidth: parseInt(thumbnailWidth, 10),
                    thumbnailHeight: parseInt(thumbnailHeight, 10),
                    thumbnailCount,
                    interval: parseInt(interval, 10),
                    columns,
                    rows,
                    storyboardCount,
                };
            });
        };

        /**
         * Get chapters info.
         *
         * @param {Object} info
         * @returns {Array.<Object>}
         */
        exports.getChapters = info => {
            const playerOverlayRenderer = info.response &&
                info.response.playerOverlays &&
                info.response.playerOverlays.playerOverlayRenderer;
            const playerBar = playerOverlayRenderer &&
                playerOverlayRenderer.decoratedPlayerBarRenderer &&
                playerOverlayRenderer.decoratedPlayerBarRenderer.decoratedPlayerBarRenderer &&
                playerOverlayRenderer.decoratedPlayerBarRenderer.decoratedPlayerBarRenderer.playerBar;
            const markersMap = playerBar &&
                playerBar.multiMarkersPlayerBarRenderer &&
                playerBar.multiMarkersPlayerBarRenderer.markersMap;
            const marker = Array.isArray(markersMap) && markersMap.find(m => m.value && Array.isArray(m.value.chapters));
            if (!marker) return [];
            const chapters = marker.value.chapters;

            return chapters.map(chapter => ({
                title: getText(chapter.chapterRenderer.title),
                start_time: chapter.chapterRenderer.timeRangeStartMillis / 1000,
            }));
        };

    }, {
        "./utils": 72,
        "m3u8stream": 58,
        "querystring": 13
    }],
    69: [function(require, module, exports) {
        const querystring = require('querystring');
        const sax = require('sax');
        const miniget = require('miniget');
        const utils = require('./utils');
        // Forces Node JS version of setTimeout for Electron based applications
        const {
            setTimeout
        } = require('timers');
        const formatUtils = require('./format-utils');
        const urlUtils = require('./url-utils');
        const extras = require('./info-extras');
        const sig = require('./sig');
        const Cache = require('./cache');


        const BASE_URL = 'https://www.youtube.com/watch?v=';


        // Cached for storing basic/full info.
        exports.cache = new Cache();
        exports.cookieCache = new Cache(1000 * 60 * 60 * 24);
        exports.watchPageCache = new Cache();
        // Cache for cver used in getVideoInfoPage
        let cver = '2.20210622.10.00';


        // Special error class used to determine if an error is unrecoverable,
        // as in, ytdl-core should not try again to fetch the video metadata.
        // In this case, the video is usually unavailable in some way.
        class UnrecoverableError extends Error {}


        // List of URLs that show up in `notice_url` for age restricted videos.
        const AGE_RESTRICTED_URLS = [
            'support.google.com/youtube/?p=age_restrictions',
            'youtube.com/t/community_guidelines',
        ];


        /**
         * Gets info from a video without getting additional formats.
         *
         * @param {string} id
         * @param {Object} options
         * @returns {Promise<Object>}
         */
        exports.getBasicInfo = async (id, options) => {
            if (options.IPv6Block) {
                options.requestOptions = Object.assign({}, options.requestOptions, {
                    family: 6,
                    localAddress: utils.getRandomIPv6(options.IPv6Block),
                });
            }
            const retryOptions = Object.assign({}, miniget.defaultOptions, options.requestOptions);
            options.requestOptions = Object.assign({}, options.requestOptions, {});
            options.requestOptions.headers = Object.assign({}, {
                // eslint-disable-next-line max-len
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/87.0.4280.101 Safari/537.36',
            }, options.requestOptions.headers);
            const validate = info => {
                let playErr = utils.playError(info.player_response, ['ERROR'], UnrecoverableError);
                let privateErr = privateVideoError(info.player_response);
                if (playErr || privateErr) {
                    throw playErr || privateErr;
                }
                return info && info.player_response && (
                    info.player_response.streamingData || isRental(info.player_response) || isNotYetBroadcasted(info.player_response)
                );
            };
            let info = await pipeline([id, options], validate, retryOptions, [
                getWatchHTMLPage,
                getWatchJSONPage,
                getVideoInfoPage,
            ]);

            Object.assign(info, {
                formats: parseFormats(info.player_response),
                related_videos: extras.getRelatedVideos(info),
            });

            // Add additional properties to info.
            const media = extras.getMedia(info);
            const additional = {
                author: extras.getAuthor(info),
                media,
                likes: extras.getLikes(info),
                dislikes: extras.getDislikes(info),
                age_restricted: !!(media && AGE_RESTRICTED_URLS.some(url =>
                    Object.values(media).some(v => typeof v === 'string' && v.includes(url)))),

                // Give the standard link to the video.
                video_url: BASE_URL + id,
                storyboards: extras.getStoryboards(info),
                chapters: extras.getChapters(info),
            };

            info.videoDetails = extras.cleanVideoDetails(Object.assign({},
                info.player_response && info.player_response.microformat &&
                info.player_response.microformat.playerMicroformatRenderer,
                info.player_response && info.player_response.videoDetails, additional), info);

            return info;
        };

        const privateVideoError = player_response => {
            let playability = player_response && player_response.playabilityStatus;
            if (playability && playability.status === 'LOGIN_REQUIRED' && playability.messages &&
                playability.messages.filter(m => /This is a private video/.test(m)).length) {
                return new UnrecoverableError(playability.reason || (playability.messages && playability.messages[0]));
            } else {
                return null;
            }
        };


        const isRental = player_response => {
            let playability = player_response.playabilityStatus;
            return playability && playability.status === 'UNPLAYABLE' &&
                playability.errorScreen && playability.errorScreen.playerLegacyDesktopYpcOfferRenderer;
        };


        const isNotYetBroadcasted = player_response => {
            let playability = player_response.playabilityStatus;
            return playability && playability.status === 'LIVE_STREAM_OFFLINE';
        };


        const getWatchHTMLURL = (id, options) => `${BASE_URL + id}&hl=${options.lang || 'en'}`;
        const getWatchHTMLPageBody = (id, options) => {
            const url = getWatchHTMLURL(id, options);
            return exports.watchPageCache.getOrSet(url, () => utils.exposedMiniget(url, options).text());
        };


        const EMBED_URL = 'https://www.youtube.com/embed/';
        const getEmbedPageBody = (id, options) => {
            const embedUrl = `${EMBED_URL + id}?hl=${options.lang || 'en'}`;
            return utils.exposedMiniget(embedUrl, options).text();
        };


        const getHTML5player = body => {
            let html5playerRes =
                /<script\s+src="([^"]+)"(?:\s+type="text\/javascript")?\s+name="player_ias\/base"\s*>|"jsUrl":"([^"]+)"/
                .exec(body);
            return html5playerRes ? html5playerRes[1] || html5playerRes[2] : null;
        };


        const getIdentityToken = (id, options, key, throwIfNotFound) =>
            exports.cookieCache.getOrSet(key, async () => {
                let page = await getWatchHTMLPageBody(id, options);
                let match = page.match(/(["'])ID_TOKEN\1[:,]\s?"([^"]+)"/);
                if (!match && throwIfNotFound) {
                    throw new UnrecoverableError('Cookie header used in request, but unable to find YouTube identity token');
                }
                return match && match[2];
            });


        /**
         * Goes through each endpoint in the pipeline, retrying on failure if the error is recoverable.
         * If unable to succeed with one endpoint, moves onto the next one.
         *
         * @param {Array.<Object>} args
         * @param {Function} validate
         * @param {Object} retryOptions
         * @param {Array.<Function>} endpoints
         * @returns {[Object, Object, Object]}
         */
        const pipeline = async (args, validate, retryOptions, endpoints) => {
            let info;
            for (let func of endpoints) {
                try {
                    const newInfo = await retryFunc(func, args.concat([info]), retryOptions);
                    if (newInfo.player_response) {
                        newInfo.player_response.videoDetails = assign(
                            info && info.player_response && info.player_response.videoDetails,
                            newInfo.player_response.videoDetails);
                        newInfo.player_response = assign(info && info.player_response, newInfo.player_response);
                    }
                    info = assign(info, newInfo);
                    if (validate(info, false)) {
                        break;
                    }
                } catch (err) {
                    if (err instanceof UnrecoverableError || func === endpoints[endpoints.length - 1]) {
                        throw err;
                    }
                    // Unable to find video metadata... so try next endpoint.
                }
            }
            return info;
        };


        /**
         * Like Object.assign(), but ignores `null` and `undefined` from `source`.
         *
         * @param {Object} target
         * @param {Object} source
         * @returns {Object}
         */
        const assign = (target, source) => {
            if (!target || !source) {
                return target || source;
            }
            for (let [key, value] of Object.entries(source)) {
                if (value !== null && value !== undefined) {
                    target[key] = value;
                }
            }
            return target;
        };


        /**
         * Given a function, calls it with `args` until it's successful,
         * or until it encounters an unrecoverable error.
         * Currently, any error from miniget is considered unrecoverable. Errors such as
         * too many redirects, invalid URL, status code 404, status code 502.
         *
         * @param {Function} func
         * @param {Array.<Object>} args
         * @param {Object} options
         * @param {number} options.maxRetries
         * @param {Object} options.backoff
         * @param {number} options.backoff.inc
         */
        const retryFunc = async (func, args, options) => {
            let currentTry = 0,
                result;
            while (currentTry <= options.maxRetries) {
                try {
                    result = await func(...args);
                    break;
                } catch (err) {
                    if (err instanceof UnrecoverableError ||
                        (err instanceof miniget.MinigetError && err.statusCode < 500) || currentTry >= options.maxRetries) {
                        throw err;
                    }
                    let wait = Math.min(++currentTry * options.backoff.inc, options.backoff.max);
                    await new Promise(resolve => setTimeout(resolve, wait));
                }
            }
            return result;
        };


        const jsonClosingChars = /^[)\]}'\s]+/;
        const parseJSON = (source, varName, json) => {
            if (!json || typeof json === 'object') {
                return json;
            } else {
                try {
                    json = json.replace(jsonClosingChars, '');
                    return JSON.parse(json);
                } catch (err) {
                    throw Error(`Error parsing ${varName} in ${source}: ${err.message}`);
                }
            }
        };


        const findJSON = (source, varName, body, left, right, prependJSON) => {
            let jsonStr = utils.between(body, left, right);
            if (!jsonStr) {
                throw Error(`Could not find ${varName} in ${source}`);
            }
            return parseJSON(source, varName, utils.cutAfterJS(`${prependJSON}${jsonStr}`));
        };


        const findPlayerResponse = (source, info) => {
            const player_response = info && (
                (info.args && info.args.player_response) ||
                info.player_response || info.playerResponse || info.embedded_player_response);
            return parseJSON(source, 'player_response', player_response);
        };


        const getWatchJSONURL = (id, options) => `${getWatchHTMLURL(id, options)}&pbj=1`;
        const getWatchJSONPage = async (id, options) => {
            const reqOptions = Object.assign({
                headers: {}
            }, options.requestOptions);
            let cookie = reqOptions.headers.Cookie || reqOptions.headers.cookie;
            reqOptions.headers = Object.assign({
                'x-youtube-client-name': '1',
                'x-youtube-client-version': cver,
                'x-youtube-identity-token': exports.cookieCache.get(cookie || 'browser') || '',
            }, reqOptions.headers);

            const setIdentityToken = async (key, throwIfNotFound) => {
                if (reqOptions.headers['x-youtube-identity-token']) {
                    return;
                }
                reqOptions.headers['x-youtube-identity-token'] = await getIdentityToken(id, options, key, throwIfNotFound);
            };

            if (cookie) {
                await setIdentityToken(cookie, true);
            }

            const jsonUrl = getWatchJSONURL(id, options);
            const body = await utils.exposedMiniget(jsonUrl, options, reqOptions).text();
            let parsedBody = parseJSON('watch.json', 'body', body);
            if (parsedBody.reload === 'now') {
                await setIdentityToken('browser', false);
            }
            if (parsedBody.reload === 'now' || !Array.isArray(parsedBody)) {
                throw Error('Unable to retrieve video metadata in watch.json');
            }
            let info = parsedBody.reduce((part, curr) => Object.assign(curr, part), {});
            info.player_response = findPlayerResponse('watch.json', info);
            info.html5player = info.player && info.player.assets && info.player.assets.js;

            return info;
        };


        const getWatchHTMLPage = async (id, options) => {
            let body = await getWatchHTMLPageBody(id, options);
            let info = {
                page: 'watch'
            };
            try {
                cver = utils.between(body, '{"key":"cver","value":"', '"}');
                info.player_response = findJSON('watch.html', 'player_response',
                    body, /\bytInitialPlayerResponse\s*=\s*\{/i, '</script>', '{');
            } catch (err) {
                let args = findJSON('watch.html', 'player_response', body, /\bytplayer\.config\s*=\s*{/, '</script>', '{');
                info.player_response = findPlayerResponse('watch.html', args);
            }
            info.response = findJSON('watch.html', 'response', body, /\bytInitialData("\])?\s*=\s*\{/i, '</script>', '{');
            info.html5player = getHTML5player(body);
            return info;
        };


        const INFO_HOST = 'www.youtube.com';
        const INFO_PATH = '/get_video_info';
        const VIDEO_EURL = 'https://youtube.googleapis.com/v/';
        const getVideoInfoPage = async (id, options) => {
            const url = new URL(`https://${INFO_HOST}${INFO_PATH}`);
            url.searchParams.set('video_id', id);
            url.searchParams.set('c', 'TVHTML5');
            url.searchParams.set('cver', `7${cver.substr(1)}`);
            url.searchParams.set('eurl', VIDEO_EURL + id);
            url.searchParams.set('ps', 'default');
            url.searchParams.set('gl', 'US');
            url.searchParams.set('hl', options.lang || 'en');
            url.searchParams.set('html5', '1');
            const body = await utils.exposedMiniget(url.toString(), options).text();
            let info = querystring.parse(body);
            info.player_response = findPlayerResponse('get_video_info', info);
            return info;
        };


        /**
         * @param {Object} player_response
         * @returns {Array.<Object>}
         */
        const parseFormats = player_response => {
            let formats = [];
            if (player_response && player_response.streamingData) {
                formats = formats
                    .concat(player_response.streamingData.formats || [])
                    .concat(player_response.streamingData.adaptiveFormats || []);
            }
            return formats;
        };


        /**
         * Gets info from a video additional formats and deciphered URLs.
         *
         * @param {string} id
         * @param {Object} options
         * @returns {Promise<Object>}
         */
        exports.getInfo = async (id, options) => {
            let info = await exports.getBasicInfo(id, options);
            const hasManifest =
                info.player_response && info.player_response.streamingData && (
                    info.player_response.streamingData.dashManifestUrl ||
                    info.player_response.streamingData.hlsManifestUrl
                );
            let funcs = [];
            if (info.formats.length) {
                info.html5player = info.html5player ||
                    getHTML5player(await getWatchHTMLPageBody(id, options)) || getHTML5player(await getEmbedPageBody(id, options));
                if (!info.html5player) {
                    throw Error('Unable to find html5player file');
                }
                const html5player = new URL(info.html5player, BASE_URL).toString();
                funcs.push(sig.decipherFormats(info.formats, html5player, options));
            }
            if (hasManifest && info.player_response.streamingData.dashManifestUrl) {
                let url = info.player_response.streamingData.dashManifestUrl;
                funcs.push(getDashManifest(url, options));
            }
            if (hasManifest && info.player_response.streamingData.hlsManifestUrl) {
                let url = info.player_response.streamingData.hlsManifestUrl;
                funcs.push(getM3U8(url, options));
            }

            let results = await Promise.all(funcs);
            info.formats = Object.values(Object.assign({}, ...results));
            info.formats = info.formats.map(formatUtils.addFormatMeta);
            info.formats.sort(formatUtils.sortFormats);
            info.full = true;
            return info;
        };


        /**
         * Gets additional DASH formats.
         *
         * @param {string} url
         * @param {Object} options
         * @returns {Promise<Array.<Object>>}
         */
        const getDashManifest = (url, options) => new Promise((resolve, reject) => {
            let formats = {};
            const parser = sax.parser(false);
            parser.onerror = reject;
            let adaptationSet;
            parser.onopentag = node => {
                if (node.name === 'ADAPTATIONSET') {
                    adaptationSet = node.attributes;
                } else if (node.name === 'REPRESENTATION') {
                    const itag = parseInt(node.attributes.ID);
                    if (!isNaN(itag)) {
                        formats[url] = Object.assign({
                            itag,
                            url,
                            bitrate: parseInt(node.attributes.BANDWIDTH),
                            mimeType: `${adaptationSet.MIMETYPE}; codecs="${node.attributes.CODECS}"`,
                        }, node.attributes.HEIGHT ? {
                            width: parseInt(node.attributes.WIDTH),
                            height: parseInt(node.attributes.HEIGHT),
                            fps: parseInt(node.attributes.FRAMERATE),
                        } : {
                            audioSampleRate: node.attributes.AUDIOSAMPLINGRATE,
                        });
                    }
                }
            };
            parser.onend = () => {
                resolve(formats);
            };
            const req = utils.exposedMiniget(new URL(url, BASE_URL).toString(), options);
            req.setEncoding('utf8');
            req.on('error', reject);
            req.on('data', chunk => {
                parser.write(chunk);
            });
            req.on('end', parser.close.bind(parser));
        });


        /**
         * Gets additional formats.
         *
         * @param {string} url
         * @param {Object} options
         * @returns {Promise<Array.<Object>>}
         */
        const getM3U8 = async (url, options) => {
            url = new URL(url, BASE_URL);
            const body = await utils.exposedMiniget(url.toString(), options).text();
            let formats = {};
            body
                .split('\n')
                .filter(line => /^https?:\/\//.test(line))
                .forEach(line => {
                    const itag = parseInt(line.match(/\/itag\/(\d+)\//)[1]);
                    formats[line] = {
                        itag,
                        url: line
                    };
                });
            return formats;
        };


        // Cache get info functions.
        // In case a user wants to get a video's info before downloading.
        for (let funcName of ['getBasicInfo', 'getInfo']) {
            /**
             * @param {string} link
             * @param {Object} options
             * @returns {Promise<Object>}
             */
            const func = exports[funcName];
            exports[funcName] = async (link, options = {}) => {
                utils.checkForUpdates();
                let id = await urlUtils.getVideoID(link);
                const key = [funcName, id, options.lang].join('-');
                return exports.cache.getOrSet(key, () => func(id, options));
            };
        }


        // Export a few helpers.
        exports.validateID = urlUtils.validateID;
        exports.validateURL = urlUtils.validateURL;
        exports.getURLVideoID = urlUtils.getURLVideoID;
        exports.getVideoID = urlUtils.getVideoID;

    }, {
        "./cache": 64,
        "./format-utils": 65,
        "./info-extras": 68,
        "./sig": 70,
        "./url-utils": 71,
        "./utils": 72,
        "miniget": 62,
        "querystring": 13,
        "sax": 63,
        "timers": 50
    }],
    70: [function(require, module, exports) {
        const querystring = require('querystring');
        const Cache = require('./cache');
        const utils = require('./utils');
        const vm = require('vm');

        // A shared cache to keep track of html5player js functions.
        exports.cache = new Cache();

        /**
         * Extract signature deciphering and n parameter transform functions from html5player file.
         *
         * @param {string} html5playerfile
         * @param {Object} options
         * @returns {Promise<Array.<string>>}
         */
        exports.getFunctions = (html5playerfile, options) => exports.cache.getOrSet(html5playerfile, async () => {
            const body = await utils.exposedMiniget(html5playerfile, options).text();
            const functions = exports.extractFunctions(body);
            if (!functions || !functions.length) {
                throw Error('Could not extract functions');
            }
            exports.cache.set(html5playerfile, functions);
            return functions;
        });

        /**
         * Extracts the actions that should be taken to decipher a signature
         * and tranform the n parameter
         *
         * @param {string} body
         * @returns {Array.<string>}
         */
        exports.extractFunctions = body => {
            const functions = [];
            const extractManipulations = caller => {
                const functionName = utils.between(caller, `a=a.split("");`, `.`);
                if (!functionName) return '';
                const functionStart = `var ${functionName}={`;
                const ndx = body.indexOf(functionStart);
                if (ndx < 0) return '';
                const subBody = body.slice(ndx + functionStart.length - 1);
                return `var ${functionName}=${utils.cutAfterJS(subBody)}`;
            };
            const extractDecipher = () => {
                const functionName = utils.between(body, `a.set("alr","yes");c&&(c=`, `(decodeURIC`);
                if (functionName && functionName.length) {
                    const functionStart = `${functionName}=function(a)`;
                    const ndx = body.indexOf(functionStart);
                    if (ndx >= 0) {
                        const subBody = body.slice(ndx + functionStart.length);
                        let functionBody = `var ${functionStart}${utils.cutAfterJS(subBody)}`;
                        functionBody = `${extractManipulations(functionBody)};${functionBody};${functionName}(sig);`;
                        functions.push(functionBody);
                    }
                }
            };
            const extractNCode = () => {
                let functionName = utils.between(body, `&&(b=a.get("n"))&&(b=`, `(b)`);
                if (functionName.includes('[')) functionName = utils.between(body, `${functionName.split('[')[0]}=[`, `]`);
                if (functionName && functionName.length) {
                    const functionStart = `${functionName}=function(a)`;
                    const ndx = body.indexOf(functionStart);
                    if (ndx >= 0) {
                        const subBody = body.slice(ndx + functionStart.length);
                        const functionBody = `var ${functionStart}${utils.cutAfterJS(subBody)};${functionName}(ncode);`;
                        functions.push(functionBody);
                    }
                }
            };
            extractDecipher();
            extractNCode();
            return functions;
        };

        /**
         * Apply decipher and n-transform to individual format
         *
         * @param {Object} format
         * @param {vm.Script} decipherScript
         * @param {vm.Script} nTransformScript
         */
        exports.setDownloadURL = (format, decipherScript, nTransformScript) => {
            const decipher = url => {
                const args = querystring.parse(url);
                if (!args.s || !decipherScript) return args.url;
                const components = new URL(decodeURIComponent(args.url));
                components.searchParams.set(args.sp ? args.sp : 'signature',
                    decipherScript.runInNewContext({
                        sig: decodeURIComponent(args.s)
                    }));
                return components.toString();
            };
            const ncode = url => {
                const components = new URL(decodeURIComponent(url));
                const n = components.searchParams.get('n');
                if (!n || !nTransformScript) return url;
                components.searchParams.set('n', nTransformScript.runInNewContext({
                    ncode: n
                }));
                return components.toString();
            };
            const cipher = !format.url;
            const url = format.url || format.signatureCipher || format.cipher;
            format.url = cipher ? ncode(decipher(url)) : ncode(url);
            delete format.signatureCipher;
            delete format.cipher;
        };

        /**
         * Applies decipher and n parameter transforms to all format URL's.
         *
         * @param {Array.<Object>} formats
         * @param {string} html5player
         * @param {Object} options
         */
        exports.decipherFormats = async (formats, html5player, options) => {
            let decipheredFormats = {};
            let functions = await exports.getFunctions(html5player, options);
            const decipherScript = functions.length ? new vm.Script(functions[0]) : null;
            const nTransformScript = functions.length > 1 ? new vm.Script(functions[1]) : null;
            formats.forEach(format => {
                exports.setDownloadURL(format, decipherScript, nTransformScript);
                decipheredFormats[format.url] = format;
            });
            return decipheredFormats;
        };

    }, {
        "./cache": 64,
        "./utils": 72,
        "querystring": 13,
        "vm": 54
    }],
    71: [function(require, module, exports) {
        /**
         * Get video ID.
         *
         * There are a few type of video URL formats.
         *  - https://www.youtube.com/watch?v=VIDEO_ID
         *  - https://m.youtube.com/watch?v=VIDEO_ID
         *  - https://youtu.be/VIDEO_ID
         *  - https://www.youtube.com/v/VIDEO_ID
         *  - https://www.youtube.com/embed/VIDEO_ID
         *  - https://music.youtube.com/watch?v=VIDEO_ID
         *  - https://gaming.youtube.com/watch?v=VIDEO_ID
         *
         * @param {string} link
         * @return {string}
         * @throws {Error} If unable to find a id
         * @throws {TypeError} If videoid doesn't match specs
         */
        const validQueryDomains = new Set([
            'youtube.com',
            'www.youtube.com',
            'm.youtube.com',
            'music.youtube.com',
            'gaming.youtube.com',
        ]);
        const validPathDomains = /^https?:\/\/(youtu\.be\/|(www\.)?youtube\.com\/(embed|v|shorts)\/)/;
        exports.getURLVideoID = link => {
            const parsed = new URL(link.trim());
            let id = parsed.searchParams.get('v');
            if (validPathDomains.test(link.trim()) && !id) {
                const paths = parsed.pathname.split('/');
                id = parsed.host === 'youtu.be' ? paths[1] : paths[2];
            } else if (parsed.hostname && !validQueryDomains.has(parsed.hostname)) {
                throw Error('Not a YouTube domain');
            }
            if (!id) {
                throw Error(`No video id found: "${link}"`);
            }
            id = id.substring(0, 11);
            if (!exports.validateID(id)) {
                throw TypeError(`Video id (${id}) does not match expected ` +
                    `format (${idRegex.toString()})`);
            }
            return id;
        };


        /**
         * Gets video ID either from a url or by checking if the given string
         * matches the video ID format.
         *
         * @param {string} str
         * @returns {string}
         * @throws {Error} If unable to find a id
         * @throws {TypeError} If videoid doesn't match specs
         */
        const urlRegex = /^https?:\/\//;
        exports.getVideoID = str => {
            if (exports.validateID(str)) {
                return str;
            } else if (urlRegex.test(str.trim())) {
                return exports.getURLVideoID(str);
            } else {
                throw Error(`No video id found: ${str}`);
            }
        };


        /**
         * Returns true if given id satifies YouTube's id format.
         *
         * @param {string} id
         * @return {boolean}
         */
        const idRegex = /^[a-zA-Z0-9-_]{11}$/;
        exports.validateID = id => idRegex.test(id.trim());


        /**
         * Checks wether the input string includes a valid id.
         *
         * @param {string} string
         * @returns {boolean}
         */
        exports.validateURL = string => {
            try {
                exports.getURLVideoID(string);
                return true;
            } catch (e) {
                return false;
            }
        };

    }, {}],
    72: [function(require, module, exports) {
        (function(process) {
            (function() {
                const miniget = require('miniget');


                /**
                 * Extract string inbetween another.
                 *
                 * @param {string} haystack
                 * @param {string} left
                 * @param {string} right
                 * @returns {string}
                 */
                exports.between = (haystack, left, right) => {
                    let pos;
                    if (left instanceof RegExp) {
                        const match = haystack.match(left);
                        if (!match) {
                            return '';
                        }
                        pos = match.index + match[0].length;
                    } else {
                        pos = haystack.indexOf(left);
                        if (pos === -1) {
                            return '';
                        }
                        pos += left.length;
                    }
                    haystack = haystack.slice(pos);
                    pos = haystack.indexOf(right);
                    if (pos === -1) {
                        return '';
                    }
                    haystack = haystack.slice(0, pos);
                    return haystack;
                };


                /**
                 * Get a number from an abbreviated number string.
                 *
                 * @param {string} string
                 * @returns {number}
                 */
                exports.parseAbbreviatedNumber = string => {
                    const match = string
                        .replace(',', '.')
                        .replace(' ', '')
                        .match(/([\d,.]+)([MK]?)/);
                    if (match) {
                        let [, num, multi] = match;
                        num = parseFloat(num);
                        return Math.round(multi === 'M' ? num * 1000000 :
                            multi === 'K' ? num * 1000 : num);
                    }
                    return null;
                };

                /**
                 * Escape sequences for cutAfterJS
                 * @param {string} start the character string the escape sequence
                 * @param {string} end the character string to stop the escape seequence
                 * @param {undefined|Regex} startPrefix a regex to check against the preceding 10 characters
                 */
                const ESCAPING_SEQUENZES = [
                    // Strings
                    {
                        start: '"',
                        end: '"'
                    },
                    {
                        start: "'",
                        end: "'"
                    },
                    {
                        start: '`',
                        end: '`'
                    },
                    // RegeEx
                    {
                        start: '/',
                        end: '/',
                        startPrefix: /(^|[[{:;,])\s?$/
                    },
                ];

                /**
                 * Match begin and end braces of input JS, return only JS
                 *
                 * @param {string} mixedJson
                 * @returns {string}
                 */
                exports.cutAfterJS = mixedJson => {
                    // Define the general open and closing tag
                    let open, close;
                    if (mixedJson[0] === '[') {
                        open = '[';
                        close = ']';
                    } else if (mixedJson[0] === '{') {
                        open = '{';
                        close = '}';
                    }

                    if (!open) {
                        throw new Error(`Can't cut unsupported JSON (need to begin with [ or { ) but got: ${mixedJson[0]}`);
                    }

                    // States if the loop is currently inside an escaped js object
                    let isEscapedObject = null;

                    // States if the current character is treated as escaped or not
                    let isEscaped = false;

                    // Current open brackets to be closed
                    let counter = 0;

                    let i;
                    // Go through all characters from the start
                    for (i = 0; i < mixedJson.length; i++) {
                        // End of current escaped object
                        if (!isEscaped && isEscapedObject !== null && mixedJson[i] === isEscapedObject.end) {
                            isEscapedObject = null;
                            continue;
                            // Might be the start of a new escaped object
                        } else if (!isEscaped && isEscapedObject === null) {
                            for (const escaped of ESCAPING_SEQUENZES) {
                                if (mixedJson[i] !== escaped.start) continue;
                                // Test startPrefix against last 10 characters
                                if (!escaped.startPrefix || mixedJson.substring(i - 10, i).match(escaped.startPrefix)) {
                                    isEscapedObject = escaped;
                                    break;
                                }
                            }
                            // Continue if we found a new escaped object
                            if (isEscapedObject !== null) {
                                continue;
                            }
                        }

                        // Toggle the isEscaped boolean for every backslash
                        // Reset for every regular character
                        isEscaped = mixedJson[i] === '\\' && !isEscaped;

                        if (isEscapedObject !== null) continue;

                        if (mixedJson[i] === open) {
                            counter++;
                        } else if (mixedJson[i] === close) {
                            counter--;
                        }

                        // All brackets have been closed, thus end of JSON is reached
                        if (counter === 0) {
                            // Return the cut JSON
                            return mixedJson.substring(0, i + 1);
                        }
                    }

                    // We ran through the whole string and ended up with an unclosed bracket
                    throw Error("Can't cut unsupported JSON (no matching closing bracket found)");
                };


                /**
                 * Checks if there is a playability error.
                 *
                 * @param {Object} player_response
                 * @param {Array.<string>} statuses
                 * @param {Error} ErrorType
                 * @returns {!Error}
                 */
                exports.playError = (player_response, statuses, ErrorType = Error) => {
                    let playability = player_response && player_response.playabilityStatus;
                    if (playability && statuses.includes(playability.status)) {
                        return new ErrorType(playability.reason || (playability.messages && playability.messages[0]));
                    }
                    return null;
                };

                /**
                 * Does a miniget request and calls options.requestCallback if present
                 *
                 * @param {string} url the request url
                 * @param {Object} options an object with optional requestOptions and requestCallback parameters
                 * @param {Object} requestOptionsOverwrite overwrite of options.requestOptions
                 * @returns {miniget.Stream}
                 */
                exports.exposedMiniget = (url, options = {}, requestOptionsOverwrite) => {
                    const req = miniget(url, requestOptionsOverwrite || options.requestOptions);
                    if (typeof options.requestCallback === 'function') options.requestCallback(req);
                    return req;
                };

                /**
                 * Temporary helper to help deprecating a few properties.
                 *
                 * @param {Object} obj
                 * @param {string} prop
                 * @param {Object} value
                 * @param {string} oldPath
                 * @param {string} newPath
                 */
                exports.deprecate = (obj, prop, value, oldPath, newPath) => {
                    Object.defineProperty(obj, prop, {
                        get: () => {
                            console.warn(`\`${oldPath}\` will be removed in a near future release, ` +
                                `use \`${newPath}\` instead.`);
                            return value;
                        },
                    });
                };


                // Check for updates.
                const pkg = require('../package.json');
                const UPDATE_INTERVAL = 1000 * 60 * 60 * 12;
                exports.lastUpdateCheck = 0;
                exports.checkForUpdates = () => {
                    if (!process.env.YTDL_NO_UPDATE && !pkg.version.startsWith('0.0.0-') &&
                        Date.now() - exports.lastUpdateCheck >= UPDATE_INTERVAL) {
                        exports.lastUpdateCheck = Date.now();
                        return miniget('https://api.github.com/repos/fent/node-ytdl-core/releases/latest', {
                            headers: {
                                'User-Agent': 'ytdl-core'
                            },
                        }).text().then(response => {
                            if (JSON.parse(response).tag_name !== `v${pkg.version}`) {
                                console.warn('\x1b[33mWARNING:\x1B[0m ytdl-core is out of date! Update with "npm install ytdl-core@latest".');
                            }
                        }, err => {
                            console.warn('Error checking for updates:', err.message);
                            console.warn('You can disable this check by setting the `YTDL_NO_UPDATE` env variable.');
                        });
                    }
                    return null;
                };


                /**
                 * Gets random IPv6 Address from a block
                 *
                 * @param {string} ip the IPv6 block in CIDR-Notation
                 * @returns {string}
                 */
                exports.getRandomIPv6 = ip => {
                    // Start with a fast Regex-Check
                    if (!isIPv6(ip)) throw Error('Invalid IPv6 format');
                    // Start by splitting and normalizing addr and mask
                    const [rawAddr, rawMask] = ip.split('/');
                    let base10Mask = parseInt(rawMask);
                    if (!base10Mask || base10Mask > 128 || base10Mask < 24) throw Error('Invalid IPv6 subnet');
                    const base10addr = normalizeIP(rawAddr);
                    // Get random addr to pad with
                    // using Math.random since we're not requiring high level of randomness
                    const randomAddr = new Array(8).fill(1).map(() => Math.floor(Math.random() * 0xffff));

                    // Merge base10addr with randomAddr
                    const mergedAddr = randomAddr.map((randomItem, idx) => {
                        // Calculate the amount of static bits
                        const staticBits = Math.min(base10Mask, 16);
                        // Adjust the bitmask with the staticBits
                        base10Mask -= staticBits;
                        // Calculate the bitmask
                        // lsb makes the calculation way more complicated
                        const mask = 0xffff - ((2 ** (16 - staticBits)) - 1);
                        // Combine base10addr and random
                        return (base10addr[idx] & mask) + (randomItem & (mask ^ 0xffff));
                    });
                    // Return new addr
                    return mergedAddr.map(x => x.toString('16')).join(':');
                };


                // eslint-disable-next-line max-len
                const IPV6_REGEX = /^(([0-9a-f]{1,4}:)(:[0-9a-f]{1,4}){1,6}|([0-9a-f]{1,4}:){1,2}(:[0-9a-f]{1,4}){1,5}|([0-9a-f]{1,4}:){1,3}(:[0-9a-f]{1,4}){1,4}|([0-9a-f]{1,4}:){1,4}(:[0-9a-f]{1,4}){1,3}|([0-9a-f]{1,4}:){1,5}(:[0-9a-f]{1,4}){1,2}|([0-9a-f]{1,4}:){1,6}(:[0-9a-f]{1,4})|([0-9a-f]{1,4}:){1,7}(([0-9a-f]{1,4})|:))\/(1[0-1]\d|12[0-8]|\d{1,2})$/;
                /**
                 * Quick check for a valid IPv6
                 * The Regex only accepts a subset of all IPv6 Addresses
                 *
                 * @param {string} ip the IPv6 block in CIDR-Notation to test
                 * @returns {boolean} true if valid
                 */
                const isIPv6 = exports.isIPv6 = ip => IPV6_REGEX.test(ip);


                /**
                 * Normalise an IP Address
                 *
                 * @param {string} ip the IPv6 Addr
                 * @returns {number[]} the 8 parts of the IPv6 as Integers
                 */
                const normalizeIP = exports.normalizeIP = ip => {
                    // Split by fill position
                    const parts = ip.split('::').map(x => x.split(':'));
                    // Normalize start and end
                    const partStart = parts[0] || [];
                    const partEnd = parts[1] || [];
                    partEnd.reverse();
                    // Placeholder for full ip
                    const fullIP = new Array(8).fill(0);
                    // Fill in start and end parts
                    for (let i = 0; i < Math.min(partStart.length, 8); i++) {
                        fullIP[i] = parseInt(partStart[i], 16) || 0;
                    }
                    for (let i = 0; i < Math.min(partEnd.length, 8); i++) {
                        fullIP[7 - i] = parseInt(partEnd[i], 16) || 0;
                    }
                    return fullIP;
                };

            }).call(this)
        }).call(this, require('_process'))
    }, {
        "../package.json": 73,
        "_process": 9,
        "miniget": 62
    }],
    73: [function(require, module, exports) {
        module.exports = {
            "name": "ytdl-core",
            "description": "YouTube video downloader in pure javascript.",
            "keywords": [
                "youtube",
                "video",
                "download"
            ],
            "version": "4.11.2",
            "repository": {
                "type": "git",
                "url": "git://github.com/fent/node-ytdl-core.git"
            },
            "author": "fent <fentbox@gmail.com> (https://github.com/fent)",
            "contributors": [
                "Tobias Kutscha (https://github.com/TimeForANinja)",
                "Andrew Kelley (https://github.com/andrewrk)",
                "Mauricio Allende (https://github.com/mallendeo)",
                "Rodrigo Altamirano (https://github.com/raltamirano)",
                "Jim Buck (https://github.com/JimmyBoh)",
                "Paweł Ruciński (https://github.com/Roki100)",
                "Alexander Paolini (https://github.com/Million900o)"
            ],
            "main": "./lib/index.js",
            "types": "./typings/index.d.ts",
            "files": [
                "lib",
                "typings"
            ],
            "scripts": {
                "test": "nyc --reporter=lcov --reporter=text-summary npm run test:unit",
                "test:unit": "mocha --ignore test/irl-test.js test/*-test.js --timeout 4000",
                "test:irl": "mocha --timeout 16000 test/irl-test.js",
                "lint": "eslint ./",
                "lint:fix": "eslint --fix ./",
                "lint:typings": "tslint typings/index.d.ts",
                "lint:typings:fix": "tslint --fix typings/index.d.ts"
            },
            "dependencies": {
                "m3u8stream": "^0.8.6",
                "miniget": "^4.2.2",
                "sax": "^1.1.3"
            },
            "devDependencies": {
                "@types/node": "^13.1.0",
                "assert-diff": "^3.0.1",
                "dtslint": "^3.6.14",
                "eslint": "^6.8.0",
                "mocha": "^7.0.0",
                "muk-require": "^1.2.0",
                "nock": "^13.0.4",
                "nyc": "^15.0.0",
                "sinon": "^9.0.0",
                "stream-equal": "~1.1.0",
                "typescript": "^3.9.7"
            },
            "engines": {
                "node": ">=12"
            },
            "license": "MIT"
        }

    }, {}]
}, {}, [56]);
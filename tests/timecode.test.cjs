const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const { test } = require('node:test');

// Exercise the actual QML functions without duplicating the formatter.
const qml = readFileSync(join(__dirname, '..', 'TimecodeDisplay.qml'), 'utf8');
function extractFunction(name) {
    const start = qml.indexOf('    function ' + name + '(');
    assert.notEqual(start, -1, 'Missing QML function: ' + name);
    const end = qml.indexOf('\n    }', start);
    assert.notEqual(end, -1, 'Missing function end: ' + name);
    return qml.slice(start, end + '\n    }'.length);
}
function formatter(rate = '1000', offset = '00:00:00:00') {
    const context = { fps: 24, fpsField: { text: rate }, offsetField: { text: offset }, playbackModel: null };
    vm.createContext(context);
    vm.runInContext(['formatTime', 'formatTimecode', 'timecodeOffsetToSeconds', 'getPlayTimeSeconds']
        .map(extractFunction).join('\n'), context);
    return context;
}

test('every millisecond across ten second boundaries is preserved', () => {
    const f = formatter();
    for (let ms = 0; ms <= 10000; ++ms) {
        const expected = '00:00:' + String(Math.floor(ms / 1000)).padStart(2, '0') + ':' + String(ms % 1000).padStart(3, '0');
        assert.equal(f.formatTime(ms / 1000), expected, 'millisecond ' + ms);
    }
});

test('minute, hour, and three-digit hour boundaries', () => {
    const f = formatter();
    for (const [ms, expected] of [
        [59999, '00:00:59:999'], [60000, '00:01:00:000'],
        [3599999, '00:59:59:999'], [3600000, '01:00:00:000'],
        [360000001, '100:00:00:001']
    ]) assert.equal(f.formatTimecode(ms, 1000, false), expected);
});

test('legacy 999 and 1000 both mean milliseconds, including offsets', () => {
    for (const rate of ['999', '1000']) {
        const f = formatter(rate, '00:00:00:125');
        assert.equal(f.formatTime(.125), '00:00:00:250');
        assert.equal(f.formatTime(.876), '00:00:01:001');
    }
});

test('ordinary frame rates keep frame counts and minimum two-digit padding', () => {
    const f = formatter();
    for (const [rate, ms, expected] of [
        [24, 500, '00:00:00:12'], [25, 400, '00:00:00:10'],
        [30, 500, '00:00:00:15'], [60, 500, '00:00:00:30'],
        [120, 500, '00:00:00:060'], [120, 999, '00:00:00:119'],
        [120, 1000, '00:00:01:000']
    ]) assert.equal(f.formatTimecode(ms, rate, false), expected);
});

test('FPS validator accepts milliseconds and decimal frame rates', () => {
    const match = qml.match(/regularExpression:\s*(\/\^.*?\$\/)/);
    assert.ok(match);
    const validator = vm.runInNewContext(match[1]);
    for (const value of ['24', '29.97', '59.94', '999', '1000', '10000']) assert.ok(validator.test(value), value);
    for (const value of ['24x5', 'abc', '1.2.3', '-24']) assert.ok(!validator.test(value), value);
});

test('missing playback model safely displays zero', () => {
    assert.equal(formatter().getPlayTimeSeconds(), 0);
});

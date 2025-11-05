# G4 Audio System - Test Suite

Comprehensive unit and integration tests for Phase 1 of the G4 Audio System.

## 📁 Test Structure

```
tests/
├── test_base.gd                      # Base test class with assertions
├── test_runner.gd                    # Main test runner script
├── test_runner.tscn                  # Test runner scene
├── unit/                             # Unit tests (isolated components)
│   ├── test_audio_parameter.gd
│   ├── test_audio_event.gd
│   ├── test_layered_audio_event.gd
│   ├── test_music_event.gd
│   └── test_audio_pool.gd
├── integration/                      # Integration tests (with singletons)
│   ├── test_audio_manager.gd
│   └── test_music_manager.gd
└── fixtures/                         # Test fixtures (audio files, etc.)
```

---

## 🚀 Running Tests

### Method 1: From Godot Editor (Recommended)

1. Open the project in Godot Editor
2. Make sure the **G4 Audio** plugin is **enabled** in Project Settings
3. Open `tests/test_runner.tscn`
4. Click the **Play Scene** button (F6)
5. Watch test results in the Output panel

### Method 2: From Command Line

```bash
# Run tests headlessly
godot --headless --path . tests/test_runner.tscn

# Or if godot is not in PATH:
/path/to/godot --headless --path . tests/test_runner.tscn
```

### Method 3: Run Individual Test

To run a single test file:

1. Open the test file (e.g., `tests/unit/test_audio_parameter.gd`)
2. Temporarily make it extend `Node` instead of `test_base.gd`
3. Create a scene with this script
4. Run the scene

---

## 📊 Test Coverage

### Unit Tests

**AudioParameter** (8 tests)
- ✅ Create with default values
- ✅ Set and get value
- ✅ Value clamping
- ✅ Interpolation
- ✅ Normalized value calculation
- ✅ Validation
- ✅ Parameter types

**AudioEvent** (9 tests)
- ✅ Create with defaults
- ✅ Event validation
- ✅ Random stream selection
- ✅ Sequential stream selection
- ✅ Volume randomization
- ✅ Pitch randomization
- ✅ Cooldown system
- ✅ Display name
- ✅ Playback modes

**LayeredAudioEvent** (7 tests)
- ✅ Create AudioLayer
- ✅ Layer volume calculation
- ✅ Layer validation
- ✅ Create event
- ✅ Event validation
- ✅ Get layer volumes at parameter value
- ✅ Crossfade behavior

**MusicEvent** (8 tests)
- ✅ Create MusicStem
- ✅ Stem validation
- ✅ Stem parameter control
- ✅ Create event
- ✅ Event validation
- ✅ Beat/bar duration calculation
- ✅ BPM variations
- ✅ Transition types

**AudioPool** (8 tests)
- ✅ Create 2D pool
- ✅ Create 3D pool
- ✅ Acquire player
- ✅ Release player
- ✅ Pool exhaustion
- ✅ Pool statistics
- ✅ Stop all players
- ✅ Player finished signal

### Integration Tests

**AudioManager** (9 tests)
- ✅ Singleton exists
- ✅ Parameter management
- ✅ Set parameter
- ✅ Parameter interpolation
- ✅ Play simple event
- ✅ Play invalid event
- ✅ BPM clock start/stop
- ✅ BPM signals
- ✅ Pool statistics

**MusicManager** (6 tests)
- ✅ Singleton exists
- ✅ Play music event
- ✅ Stop music
- ✅ Music signals
- ✅ Stem control
- ✅ Query state

**Total: 55 tests**

---

## ✍️ Writing New Tests

### Creating a Unit Test

```gdscript
## Unit tests for MyComponent
extends "res://tests/test_base.gd"

func run_tests():
	test("Test description", test_function_name)
	test("Another test", test_another_function)

func test_function_name():
	var component = MyComponent.new()
	assert_not_null(component, "Should be created")
	assert_equal(component.value, 42, "Value should be 42")
```

### Available Assertions

```gdscript
# Boolean checks
assert_true(condition, "message")
assert_false(condition, "message")

# Equality
assert_equal(actual, expected, "message")
assert_not_equal(actual, expected, "message")

# Null checks
assert_null(value, "message")
assert_not_null(value, "message")

# Numeric comparisons
assert_almost_equal(actual, expected, epsilon, "message")
assert_in_range(value, min, max, "message")

# Type checks
assert_is_type(value, Type, "message")

# Object checks
assert_has_method(object, "method_name", "message")

# Array checks
assert_array_size(array, expected_size, "message")
```

### Adding a Test to the Runner

Edit `tests/test_runner.gd` and add your test file to the `test_files` array:

```gdscript
var test_files: Array[String] = [
	"res://tests/unit/test_audio_parameter.gd",
	"res://tests/unit/test_your_new_test.gd",  # Add here
	# ...
]
```

---

## 🐛 Troubleshooting

### Tests Not Running

**Problem:** Tests don't start when running test_runner.tscn

**Solution:**
- Ensure G4 Audio plugin is enabled
- Check Output panel for errors
- Verify test files exist at specified paths

### AudioManager/MusicManager Not Found

**Problem:** Integration tests fail with "AudioManager not found"

**Solution:**
- The plugin must be enabled for singletons to be registered
- Restart Godot after enabling the plugin
- Check Project → Project Settings → Autoload

### Async Tests Timing Out

**Problem:** Tests with `await` hang indefinitely

**Solution:**
- Use `await get_tree().process_frame` for immediate waits
- Use `await get_tree().create_timer(seconds).timeout` for timed waits
- Ensure timers complete before test ends

### Test Failing on CI/CD

**Problem:** Tests pass locally but fail on CI

**Solution:**
- Use longer timeouts for async operations on CI
- Check for race conditions
- Ensure test data exists in repository

---

## 📈 Test Results Format

Tests output results in the following format:

```
======================================================================
G4 AUDIO SYSTEM - TEST SUITE
======================================================================
Running 7 test suites...

----------------------------------------------------------------------
Loading: test_audio_parameter.gd
----------------------------------------------------------------------
[TEST] Create parameter with default values
  ✓ PASSED
[TEST] Set and get parameter value
  ✓ PASSED
...

======================================================================
FINAL TEST RESULTS
======================================================================
✓ test_audio_parameter.gd - Passed: 8, Failed: 0
✓ test_audio_event.gd - Passed: 9, Failed: 0
...
----------------------------------------------------------------------
Total Passed: 55
Total Failed: 0
Total Tests:  55

======================================================================
✓✓✓ ALL TESTS PASSED! ✓✓✓
======================================================================
```

---

## 🎯 Test Best Practices

1. **Keep tests isolated** - Each test should be independent
2. **Test one thing** - Each test should verify one specific behavior
3. **Use descriptive names** - Test names should explain what they test
4. **Clean up resources** - Free objects after testing
5. **Avoid flaky tests** - Don't rely on exact timing or randomness
6. **Test edge cases** - Test minimum, maximum, and boundary values
7. **Document expected behavior** - Add comments for complex tests

---

## 🔄 Continuous Integration

### GitHub Actions Example

```yaml
name: Run Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install Godot
        run: |
          wget https://downloads.tuxfamily.org/godotengine/4.2/Godot_v4.2-stable_linux.x86_64.zip
          unzip Godot_v4.2-stable_linux.x86_64.zip
      - name: Run Tests
        run: |
          ./Godot_v4.2-stable_linux.x86_64 --headless --path . tests/test_runner.tscn
```

---

## 📝 Future Test Additions

For Phase 2 and beyond, add tests for:

- AudioEventPlayer2D node
- AudioEventPlayer3D advanced features
- MusicPlayer node
- AudioParameterDriver
- Inspector plugins
- Audio browser dock
- Performance benchmarks
- Memory leak detection
- Thread safety (if applicable)

---

## 🙏 Contributing

When adding new features to G4 Audio:

1. Write tests FIRST (Test-Driven Development)
2. Run existing tests to ensure no regressions
3. Add tests for new functionality
4. Update this documentation
5. Ensure all tests pass before submitting PR

---

**All tests passing = Phase 1 is stable!** ✅

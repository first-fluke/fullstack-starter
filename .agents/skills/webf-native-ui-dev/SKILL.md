---
name: webf-native-ui-dev
description: Develop custom native UI libraries based on Flutter widgets for WebF. Create reusable component libraries that wrap Flutter widgets as web-accessible custom elements.
---

# WebF Native UI Dev

This skill guides the development of custom native UI components for **WebF** (Web on Flutter). It bridges Flutter widgets to standard HTML custom elements.

## Concept

WebF allows you to render HTML/CSS using Flutter's rendering engine. This skill helps you expose complex Flutter widgets as `<custom-element>` tags usable in HTML.

## Workflow

1.  **Create Flutter Widget**: Build the widget using standard Flutter code.
2.  **Define Element Class**: Create a class extending `WidgetElement`.
3.  **Register Custom Element**: Use `defineCustomElement` to map the tag name to the class.

## Example

```dart
import 'package:webf/webf.dart';
import 'package:flutter/material.dart';

// 1. Define the Element
class FlutterButtonElement extends WidgetElement {
  FlutterButtonElement(BindingContext? context) : super(context);

  @override
  Widget build(BuildContext context, List<Widget> children) {
    return ElevatedButton(
      onPressed: () {
        // Dispatch custom event to JS
        dispatchEvent(Event('click'));
      },
      child: Text(getAttribute('label') ?? 'Click Me'),
    );
  }
}

// 2. Register (usually in main.dart)
void main() {
  WebF.defineCustomElement('flutter-button', (context) => FlutterButtonElement(context));
  runApp(MyApp());
}
```

## Usage in HTML

```html
<flutter-button label="Submit Order" id="btn"></flutter-button>
<script>
  document.getElementById('btn').addEventListener('click', () => {
    console.log('Button clicked via Flutter!');
  });
</script>
```

## Best Practices

- **Attributes**: Map HTML attributes to Widget properties.
- **Events**: Dispatch standard DOM events from Flutter user interactions.
- **Performance**: Avoid heavy computations in the `build` method; use state management.

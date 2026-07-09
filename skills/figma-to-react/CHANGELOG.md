# Changelog

## 1.0.0

- Initial release
- Stack-agnostic workflow for translating a Figma design into React code
- Detects the target project's existing styling approach, tokens, components, and resolution/responsiveness conventions before implementing
- Required Figma MCP flow: get_design_context, get_metadata, get_screenshot, get_variable_defs
- Anti-hallucination constraints for styles, colors, borders, positioning, and spacing
- Screenshot-based 1:1 verification step

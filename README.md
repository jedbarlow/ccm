# Coding Context Manager

This project is super messy and in early development and not intended to be user friendly (or even
readable) yet.

## Problem

Language models are getting smarter and more capable of code generation and modification, like Open
AI's GPT3.5 and GPT4 models, but the models still have a limited input size for context and
struggle to suggest fully contextualized code changes without carefully crafted input.

For example if you have a large Rails project, you can't simply dump all the files into a prompt and
ask the model to suggest the change you want, as this will exceed the input size limit. Ultimately
as the models improve and as multi-step use of the models develops this kind of low-effort prompting
is likely to become the standard way of programming. In the meantime however, the models can be used
highly effectively with the relevant code snippets manually identified within a larger project.
That's where this tool comes in, ccm.

## Solution

CCM lets you identify the relevant prompt context in your project with simple, english comments.
Then the context can be used to quickly generate a code change prompt.

## Usage

TODO

## Installation

TODO

## Development notes
- 2023-05-15: The GPT4 prompt seems to be slow (taking 5-15 seconds or so per call), so as a
  performance optimization I added caching of snippets keyed by a hash of the file content. The file
  content includes the context marker comment itself, so any channges to the file including the
  marker will result in a new, concise snippet version of the file being cached and used in the
  prompts.
- 2023-05-15: Initially I tried just using comments to simply identify which files from the project
  were relevant, but dumping entire files into the prompt quickly exceeded the input size limit. To
  solve this, I moved to identifying the relevant context within files for more concise prompts.

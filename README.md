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

CCM lets you identify the relevant prompt context in your project with simple, English comments.
Then the context can be used to quickly generate a code change prompt.

CCM is a multi-step application of LLMs to first create relevant snippets from in-code context
markers, and then use the snippets to generate a prompt for the desired code change. This helps keep
the prompt an acceptable size for input to the models while being effective at conveying the
necessary information for the model to suggest a high quality and precise code change.

## Usage

- Add context markers, (a comment including the verbatim, capitalized text `IMPORTANT CONTEXT`), in
  places in your code that may be relevant to a change you want to make.
  - Since GPT4 is used to collapse the file down, it may work to farther specify the context using
    English, for example `IMPORTANT CONTEXT: full class with method bodies`, though this is still a
    topic of experimentation.
- Run the command `ccm` from your project root directory to list the files with context markers.
- Run the command `ccm c "TASK DESCRIPTION"` from your project root directory to generate a prompt
  for a code change.
- Run the command `ccm cc "TASK DESCRIPTION"` to automatically copy the prompt to your clipboard
  (only works on mac right now, using the `pbcopy` command).
- Paste the prompt into a GPT4 chat session.

## Installation

- Clone the respository
- Add the path to the repository to your `PATH` environment variable.
- Add a `CCM_OPENAI_KEY` environment variable with your OpenAI API key (must have access to the GPT4
  models).
- Add a `CCM_PROJECT_DESCRIPTION` environment variable with a technology-focused description of your
  project. E.g. "a rails project using hotwire and stimulus".

It's best to manage the environment variables per project. `direnv` is a good solution for this.

## Development notes
- 2023-05-24: I'm finding a few pattern emerging as I try out ccm. There seem to be three basic
  kinds of context and two modes of usage.

  The contexts are the following.
  - None
  - Marked
  - Auto

  None would be for example just to use the current selection or file as input for a code change.
  Marked is to use the manual context markers from within the project code. Auto would be to
  automatically select the context files using GPT based on a given task. There could possibly be a
  combination of these, for example using both the context markers and auto context, but I'm not
  sure about the need for that yet.

  The two modes are
  - In-editor selection replacement
  - Out-of-editor chat prompting

  The selection replacement option is best run with editor commands to operate on the current
  selection and allow a code change / task description to be entered and then replace the current
  selection with the output. I'm using a custom nvim command for this right now. I can see this
  feature needs to be parameterized with a context specification, e.g. None, Marked, Auto, or a
  combination. The chat prompting is when you want to make a bigger change involving multiple files,
  or to generate a new file. The workflow in this case is to copy a generated prompt into a GPT4
  chat session, and then copy and paste the snippets back into your code. It's a bit cumbersome, but
  the prompt generation with context management helps a lot. One advantage with using an
  out-of-editor chat session for this is that you can conversationally work with the code snippets
  before bringing them back into your project.
- 2023-05-15: The GPT4 api seems to be slow (taking 30+ seconds or so per call), so as a performance
  optimization I added caching of snippets keyed by a hash of the file content. The file content
  includes the context marker comment itself, so any channges to the file including the marker will
  result in a new, concise snippet version of the file being cached and used in the prompts.
- 2023-05-15: Initially I tried just using comments to simply identify which files from the project
  were relevant, but dumping entire files into the prompt quickly exceeded the input size limit. To
  solve this, I moved to identifying the relevant context within files for more concise prompts.

# Coding Context Manager

This project is super messy and in early development and not intended to be user friendly (or even
readable) yet.

## Problem

Language models are getting smarter and more capable of code generation and modification, like Open
AI's GPT3.5 and GPT4 models, but the models still have a limited input size for context and
struggle to suggest fully contextualized code changes without carefully crafted input.

For example if you have a large Rails project, you can't simply dump all the files into a prompt and
ask the model to suggest the change you want as this will exceed the input size limit. Ultimately as
the models improve this kind of low-effort prompting is likely to form the basis for how coding is
done. However in the meantime, the models can be used highly effectively with the relevant code
snippets manually identified within a larger project or automatically identified with a multi-step
use of the models. That's where this tool comes in, ccm.

## Solution

CCM lets you identify the relevant prompt context in your project with simple, English comments.
Then the context can be used to quickly generate a code change prompt.

CCM is a multi-step application of LLMs to first create relevant snippets from in-code context
markers, and then use the snippets to generate a prompt for the desired code change. This helps keep
the prompt an acceptable size for input to the models while being effective at conveying the
necessary information for the model to suggest a high quality and precise code change.

## Usage

### Mark context
You can place context markers throught your code to indicate which code is relevant to a change you
want to make. A context marker is simply the text `IMPORTANT CONTEXT` placed in a file, usually
within a code comment and on its own line.

- Add context markers in places in your code that may be relevant to a change you want to make.
  - Since GPT4 is used to collapse the file down into a smaller snippet, it may work to farther
    specify the context using English, for example `IMPORTANT CONTEXT: full class with method
    bodies`, though this is still a topic of experimentation.
  - `IMPORTANT CONTEXT: file` is a special marker that indicates to skip snippetization and just
    use the whole file. Use this when you know all the details in the file are relevant to a change
    you want to make.
- Run the command `ccm` from your project root directory to list current context markers.
- Run the command `ccm c` from your project root directory to remove all context markers (delete all
  lines from files that contain a context marker). This is helpful if you want to quickly set up new
  context markers for a new change.

### Generate a task prompt
To generate a prompt you can copy and paste into a GPT4 chat session, use the following steps. This
mode of usage saves you the effort of forming the prompt yourself from the various relevant code
snippets.

1. Run the command following commands from your project root directory to generate a code change
   prompt.
  - `ccm generate m TASK_DESCRIPTION`: use marked context
  - `ccm generate a TASK_DESCRIPTION`: use automatic context
  - `ccm generate ma TASK_DESCRIPTION`: use marked and automatic context
2. Run the command `ccm gc CONTEXT TASK_DESCRIPTION` to automatically copy the prompt to your
   clipboard (only works on mac right now, using the `pbcopy` command).
3. Paste the prompt into a GPT4 chat session.

### Modify code
To generate code that you can directly copy and paste or pipe into other tools, use the following
steps. This mode of usage integrates well into editor commands (see the vim/nvim command examples).

1. Run the command following commands from your project root directory to generate a code change
   prompt.
  - `ccm modify m --quiet TASK_DESCRIPTION CODE`: use the marked context
  - `ccm modify a --quiet TASK_DESCRIPTION CODE`: use automatic context
  - `ccm modify ma --quiet TASK_DESCRIPTION CODE`: use marked and automatic context
  - Optionally use the `--stdin` option to pipe the code in through standard input rather than as a
    parameter.

## Installation

- Clone the respository
- Add the path to the repository to your `PATH` environment variable.
- Add a `CCM_OPENAI_KEY` environment variable with your OpenAI API key (must have access to the GPT4
  models).
- Add a `CCM_PROJECT_DESCRIPTION` environment variable with a technology-focused description of your
  project. E.g. "a rails project using hotwire and stimulus".

If you use `direnv`, then you can add the following snippet to your `.envrc` file in a given
project (modify appropriately):

```bash
export PATH="$PATH:$HOME/PATH/TO/CCM"
export CCM_OPENAI_KEY="..."
export CCM_PROJECT_DESCRIPTION="PROJECT DESCRIPTION"
#export CCM_IGNORE_DIRS=""
#export CCM_IGNORE_FILES=""
#export CCM_CONTEXT_MARKER="CUSTOM CONTEXT MARKER"
```

### vim/nvim integration
- Add the following snippet to your vim/nvim init script
  ```
  command! -nargs=1 -range=% M    <line1>,<line2>!ccm modify n  --model=gpt4 --stdin --quiet <args>
  command! -nargs=1 -range=% Mm   <line1>,<line2>!ccm modify m  --model=gpt4 --stdin --quiet <args>
  command! -nargs=1 -range=% Mma  <line1>,<line2>!ccm modify ma --model=gpt4 --stdin --quiet <args>
  command! -nargs=1 -range=% Ma   <line1>,<line2>!ccm modify a  --model=gpt4 --stdin --quiet <args>
  command! -nargs=1 -range=% M3   <line1>,<line2>!ccm modify n  --model=gpt3 --stdin --quiet <args>
  command! -nargs=1 -range=% M3m  <line1>,<line2>!ccm modify m  --model=gpt3 --stdin --quiet <args>
  command! -nargs=1 -range=% M3ma <line1>,<line2>!ccm modify ma --model=gpt3 --stdin --quiet <args>
  command! -nargs=1 -range=% M3a  <line1>,<line2>!ccm modify a  --model=gpt3 --stdin --quiet <args>
  ```

## Development notes
- 2023-05-25: Noticed that sometimes there are typos in the output from GPT4, for example in one
  case it generated a method called `iniitalize` instead of `initialize`. Probably such cases will
  become less frequent over time as OpenAI's models improve.
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

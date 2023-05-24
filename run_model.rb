require_relative "models"
require_relative "utils"

model = ARGV[0]
change = ARGV[1]
code = ARGV[2]

ChosenModel = (model.downcase == "gpt4" ? GPT4 : GPT35)

result = ChosenModel.new.complete(<<~PROMPT)
Make the specified code changes to the following code snippet. Respond with just the code, no explanations.

Change: #{change}

Code:
```
#{code}
```
PROMPT

puts Utils.extract_first_code_snippet(result)

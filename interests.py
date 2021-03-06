from utils import load
from prompt_toolkit.completion import WordCompleter
from prompt_toolkit.shortcuts import CompleteStyle, prompt
from ruamel.yaml.comments import CommentedMap


class Interests:
    def __init__(self):
        self.interests = load("interests")
        self.word_completer = WordCompleter(flatten_interests(self.interests),
                                            sentence=True,
                                            match_middle=True,
                                            ignore_case=True)

    def query_for_interest(self):
        return prompt(
            "Pick an interest: ", completer=self.word_completer,
            complete_while_typing=True,
            complete_style=CompleteStyle.MULTI_COLUMN,
        )


# Interests is a weird nested list-of-dicts because of bad yaml. Probably should
# make yaml better formatted, but it "reads" nicely the way it is.
# also should add non-root nodes too
def flatten_interests(node, chain="", current_list=[]):
    def get_chain(chain, name):
        if chain == "":
            return name
        return chain + " / " + name

    for child in node:
        if type(child) is CommentedMap:
            # if a dict, will map to a list of (possibly a combination) of more
            # dicts and leaf nodes
            keys = list(child.keys())
            assert(len(keys) == 1)
            new_chain = get_chain(chain, keys[0])
            current_list.append(new_chain)
            flatten_interests(
                child[keys[0]],
                chain=new_chain,
                current_list=current_list)
        else:
            # it's just a string
            current_list.append(get_chain(chain, child))
    return current_list


def query_interests(thing):
    interests = Interests()  # TODO: cache somewhere
    new_interests = set()
    while True:
        print(f"Adding interest tags for {thing}")
        print("(Enter nothing to continue)")
        response = interests.query_for_interest()
        if response == "":
            break
        new_interests.add(response)
    return new_interests


if __name__ == "__main__":
    interests = Interests()
    print(interests.query_for_interest())

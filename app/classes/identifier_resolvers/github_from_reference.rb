# Copyright (c) 2014 Public Library of Science

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

module IdentifierResolvers
  class GithubFromReference < Base

    def resolve
      unresolved_references.each{ |id, node|
        info = extract_info(node)
        set_result(id, info)
      }
    end

    private

    #@todo: In theory it would be possible to call the github apis to get
    # repo and commit descriptions, etc to provide more info
    # You can also get all commiters to a repo or the person who made a commit (if any)
    # As a next step you can call the /user/:login api to get the user's
    # name, email, avatar, etc

    def extract_info(node)
      id = Id::Github.extract(node.text)

      return nil unless id.present?
      info = {
          id_source:  :ref,
          id:         id,
          id_type:    :github,
      }
    end

  end
end

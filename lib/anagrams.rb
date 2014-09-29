require 'set'

class Anagramizer
  LIMIT = 20
  NIL = lambda { return nil }
  CLEAN = lambda { |w| w.gsub!(/\W+/, ''); w.downcase! }

  def initialize(lists, opts = {})
    @clean = opts[:clean] || CLEAN
    lists = validate_lists lists
    @translator = {'' => 0}
    lists[-1].each { |w| @translator[w] = @translator.size }
    @offset = nil
    lists[-1].each do |w|
      ords = w.split(//).map { |c| c.ord }
      ords.each do |o|
        if @offset.nil?
          @offset = o
        else
          @offset = o if o < @offset
        end
      end
    end
    @offset -= 1
    @tries = []
    lists.each { |list| trie, known = trieify list; @tries.push [trie, known] }
    @translator = [''] + lists[-1]
    @limit = opts[:limit] || LIMIT
    @sorted = !!opts[:sorted]
    @min = opts[:min]
    raise ':min must be a postive integer' unless @min.nil? || posint(@min)
  end

  def anagrams(phrase, opts = {})
    return [] if phrase.nil?
    @clean.(phrase)
    return [] unless phrase.length
    sorted = opts[:sorted] || @sorted
    min = opts[:min] || @min
    raise ':min must be a postive integer' unless min.nil? || posint(min)
    i = opts[:start_list] || 0
    pairs = @tries
    if i > 0
      raise 'impossible index for start list: #{i}' unless pairs[i]
      i = pairs.length + i if i < 0
      pairs = pairs[i ... pairs.length]
    end
    counts = counts(phrase)
    jumps counts
    indices counts
    anagrams = []
    pairs.each do |pair|
      @trie, @known = pair
      next unless all_known? counts
      @cache = {}
      anagrams = anagramize(counts)
      next unless anagrams.length > 0
      next if min && anagrams.length < min
      break
    end
    anagrams.map! { |a| a.map { |w| @translator[w] } }
    if sorted
      anagrams.sort! do |a, b|
        ordered = a.length < b.length ? 1 : -1
        d, e = a, b
        d, e = b, a if ordered == -1
        s = -ordered
        (0...d.length).each do |i|
          c = d[i] <=> e[i]
          if c != 0
            s = ordered * c
            break
          end
        end
        s
      end
    end
    return anagrams
  end

  def key(phrase)
    return nil if phrase.nil?
    phrase = phrase.dup
    @clean.(phrase)
    return nil if phrase.length == 0
    counts = []
    lowest = nil
    phrase.split(//).map { |c| c.ord - @offset }.each do |i|
      if lowest.nil?
        lowest = i
      else
        lowest = i if i < lowest
      end
      counts[i] ||= 0
      counts[i] += 1
    end
    counts = counts[lowest ... counts.length]
    counts.map! { |i| i.nil? ? '' : i }
    suffix = counts.join '.'
    suffix.gsub!(/\.{3,}/) { |m| ".(#{m.length - 2})." }
    return "#{lowest}:#{suffix}"
  end

  def clean(phrase)
    raise 'nil phrases cannot be cleaned' if phrase.nil?
    phrase = phrase.dup
    @clean.(phrase)
    return phrase
  end

  def iterator(phrase, opts = {})
    return NIL if phrase.nil?
    opts[:sorted] ||= @sorted
    phrase = phrase.dup
    @clean.(phrase)
    return NIL if phrase.length == 0
    i = opts[:start_list] || 0
    pairs = @tries
    if i > 0
      raise "impossible index for start list: #{i}" if pairs[i].nil?
      i = pairs.length + i if i < 0
      pairs = pairs[0...pairs.length]
    end
    return super_iterator pairs, phrase, opts
  end

  private

  def super_iterator(pairs, phrase, opts)
    counts = counts(phrase)
    jumps counts
    indices counts
    cache = {}
    i = iter(pairs, counts, opts)
    return lambda do
      rv = nil
      loop do
        rv = i.()
        return nil unless rv
        key = rv.sort.join ','
        redo if cache[key]
        cache[key] = true
        break
      end
      rv.map! { |v| @translator[v] }
      rv.sort! if opts[:sorted]
      return rv
    end
  end

  def iter(pairs, counts, opts)
    total = 0
    @indices.each { |i| total += counts[i] }
    t = @tries.dup
    i = nil
    return lambda do
      rv = nil
      loop do
        unless i
          if t.length > 0
            pair = t.shift
            trie, known = @trie, @known
            @trie, @known = pair
            unless all_known? counts
              @trie, @known = trie, known
              redo
            end
            words = words_in counts, total
            unless worth_pursuing? counts, words
              @trie, @known = trie, known
              redo
            end
            i = sub_iterator pairs, words, opts
            @trie, @known = trie, known
          else
            return rv
          end
        end
        rv = i.()
        unless rv
          i = nil
          redo
        end
        break
      end
      return rv
    end
  end

  def sub_iterator(tries, words, opts)
    pairs = words
    return lambda do
      while pairs.length > 0
        if opts[:random]
          i = rand pairs.length
          if i > 0
            p = pairs[0]
            pairs[0] = pairs[i]
            pairs[i] = p
          end
        end
        w, s = pairs[0]
        unless s.is_a? Proc
          if any? s
            s = iter tries, s, opts
          else
            first = true
            s = lambda { return nil unless first; first = false; return [] }
          end
          pairs[0][1] = s
        end
        remainder = s.()
        unless remainder
          pairs.shift
          next
        end
        return [w] + remainder
      end
      return nil
    end
  end

  def worth_pursuing?(counts, words)
    c = nil
    @indices.each do |i|
      c = counts[i]
      next unless c > 0
      r = false
      words.each do |w|
        if w[1][i] < c
          r = true
          break
        end
      end
      next if r
      return false
    end
    return true
  end

  def anagramize(counts)
    total = 0
    @indices.each { |i| total += counts[i] }
    key = nil
    if total <= @limit
      key = counts.join ','
      cached = @cache[key]
      return cached if cached
    end
    anagrams = []
    words = words_in counts, total
    if all_touched? counts, words
      words.each do |w|
        word, c = w
        if any? c
          anagramize(c).each { |a| anagrams.push [word] + a }
        else
          anagrams.push [word]
        end
      end
      seen = {}
      anagrams.select! do |a|
        k = a.sort.join ' '
        s = !seen[k]
        seen[k] = true
        s
      end
    end
    @cache[key] = anagrams if key
    return anagrams
  end

  def any?(counts)
    counts.each { |c| return true if c > 0 }
    return false
  end

  def all_touched?(counts, words)
    c = nil
    tallies = []
    good_indices = []
    words.each do |w|
      wc = w[1]
      @indices.each do |i|
        c = counts[i]
        next unless c > 0
        good_indices[i] ||= i
        if wc[i] < c
          tallies[i] ||= 0
          tallies[i] += 1
        end
      end
    end

    # if any letter count failed to change, there's no hope
    return false unless good_indices.length > 0
    good_indices.each do |i|
      next unless i && i > 0
      t = tallies[i]
      return false if t.nil? or t == 0
    end

    # find the letter with the fewest possibilities
    best = min = n = nil
    good_indices.each do |i|
      next unless i && i > 0
      n = tallies[i]
      if best.nil? or n < min
        best = i
        min = n
      end
    end

    # only retain those branches which affected a particular letter
    # all possibilities will exist among their ramifications
    c = counts[best]
    words.select! { |w| w[1][best] < c }

    return true
  end

  # finds all the words one can make out of some subset of the characters
  # at hand (the counts)
  # @param [Object] counts
  # @param [Object] total
  # @return [Array<Array<>>]
  def words_in(counts, total)
    words = []
    stack = [[0, @trie]]
    loop do
      c, level = stack[-1] # character and sub-trie
      if c == -1 or c >= level.length
        break if stack.length == 1 # tried everything
        # roll back probationary changes
        stack.pop
        total += 1
        top = stack[-1]
        counts[top[0]] += 1
        top[0] = @jumps[top[0]]
      else
        l = level[c]
        if l # trie holds corresponding node/value
          if c > 0 # character (node)
            if counts[c] > 0 # we have this character
              stack.push [0, l]
              counts[c] -= 1
              total -= 1
            else # try next
              stack[-1][0] = @jumps[c]
            end
          else # terminal (value)
            words.push [l, counts.dup]
            if total > 0 # still more characters to tru
              stack[-1][0] = @jumps[c]
            else
              stack.pop
              total += 1
              top = stack[-1]
              counts[top[0]] += 1
              top[0] = @jumps[top[0]]
            end
          end
        else # try the next possible character
          stack[-1][0] = @jumps[c]
        end
      end
    end
    return words
  end

  def all_known?(counts)
    return false if counts.length > @known.length
    (0...counts.length).each { |i| return false if counts[i] > 0 and !@known[i] }
    return true
  end

  def indices(counts)
    @indices = (0...counts.length).select { |i| counts[i] > 0 }
  end

  def jumps(counts)
    @jumps = Array.new(counts.length, 0)
    j = 0
    loop do
      n = next_jump counts, j
      break unless n
      @jumps[j] = n
      j = n
    end
    @jumps[-1] = -1
  end

  def next_jump(counts, j)
    (j+1...counts.length).each { |i| return i if counts[i] > 0 }
    return false
  end

  def counts(phrase)
    counts = []
    phrase.split(//).map { |c| c.ord - @offset }.each { |i| counts[i] ||= 0; counts[i] += 1 }
    (0...counts.length).each { |i| counts[i] ||= 0 }
    return counts
  end

  def posint(n)
    return n.class == Fixnum && n > 0
  end

  def validate_lists(lists)
    raise '' if lists.nil? or !lists.is_a? Array or lists.length == 0
    lists = [lists] unless lists[0].is_a? Array
    lists.each do |l|
      l.select! { |w| !w.nil? }
      l.each { |w| @clean.(w) }
      l.select! { |w| w.length > 0 }
      l.uniq!
      raise 'empty list' unless l.length > 0
    end
    (1 ... lists.length).each do |i|
      prior, list = lists[i - 1, i]
      raise 'lists misordered by length' if prior.length >= list.length
      s = Set.new list
      prior.each { |w| raise 'smaller lists must be subsumed by larger' unless s.include? w }
    end
    return lists
  end

  def trieify(list)
    base = []
    known = []
    list.each do |word|
      chars = word.split(//).map { |c| c.ord - @offset }
      learn known, chars
      add base, chars, word
    end
    return base, known
  end

  def add(base, chars, word)
    i = chars.shift
    if i
      base[i] ||= []
      add base[i], chars, word
    else
      base[0] = @translator[word]
    end
  end

  def learn(known, new)
    new.each { |o| known[o] = true }
  end

end

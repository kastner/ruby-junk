TOTAL = 15
CHAR = "*"
EMPTY = "."

max = (TOTAL/3 + 1) * 2 - 1

(TOTAL + 1).times do |i|
  if i < TOTAL / 3
    s = (i + 1) * 2 - 1
    s2 = EMPTY * (max - s) + CHAR * s
    s3 = s2 + CHAR + s2.reverse
    puts s3 + s3.reverse
  else
    from_top = i - TOTAL / 3
    line = from_top * 4
    s = ((TOTAL * 3) - line)
    s2 = TOTAL * 3 - s
    puts EMPTY * (s2 / 2) + CHAR * s + EMPTY * (s2 / 2)
  end
end

"""New module to compute fast difference less than value
"""

class Tab():
    """A simple class containing result of partial matrice
    store diff value in dict of i,j
    """
    def __init__(self):
        self.coord = {}
    
    def get_value(self, i, j):
        """Return 1000 if value not present"""
        return self.coord.get(i, {}).get(j, 1000)

    def add_value(self,i,j,k):
        self.coord.setdefault(i,{})
        self.coord[i][j] = k
    
    def get_next_line(self, i):
        return [*self.coord.get(i,{}).keys()]
            
    def get_line_values(self, i):
        return [*self.coord.get(i,{}).values()]

    def __len__(self):
        return len(self.coord)

    def __repr__(self):
        return str(self.coord)

def diff_less_than(seq1, seq2, diff):
   """Verify that 2 string as less than n difference
   This version correpond to complete seq
   >>> diff_less_than( "A", "AB", 2)
   True
   >>> diff_less_than( "ABGVGS", "ABCVGS", 1)
   True
   >>> diff_less_than("ABGVGST", "ABCVGS", 1)
   False
   >>> diff_less_than("ABGVGST", "ABCVGS", 2)
   True
   """
   # seq1 must be more than seq2
   if len(seq1) > len(seq2):
      return diff_less_than(seq2, seq1, diff)
   
   m, n = len(seq1), len(seq2)
   if m <=diff:
       return True
   
   #initialisation
   tab = Tab()
   for j in range(0, min(n,diff)+1):
       tab.add_value(0,j,j)
       
   for i in range(0,m):
       keys = tab.get_next_line(i)
       ## No possibility 
       if len(keys) == 0:
           return False
       ## On ajoute un element
       if max(keys) != n:
           keys.append(max(keys)+1)
       for j in range(min(keys), max(keys)+1):
           j -= 1
           cost  = ( seq1[i] != seq2[j] ) 
           k = min(tab.get_value(i,j)+cost, #substitution 
                   tab.get_value(i,j+1)+1, #deletion
                   tab.get_value(i+1,j) +1) #insertion
           if k<=diff:
               tab.add_value(i+1, j+1, k)

   if tab.get_value(m,n) <= diff:
       return True
   else:
       return False

def diff_less_than_nogap(seq1, seq2, diff):
   """Verify that 2 string as less than n difference
   This version correspond to partial alignement
   >>> diff_less_than_nogap( "A", "AB", 2)
   True
   >>> diff_less_than_nogap("BGVGS", "AABCVGS", 1)
   True
   >>> diff_less_than_nogap("ABGVSTT", "ABCVGS", 1)
   False
   >>> diff_less_than_nogap("ABGVSTT", "ABCVGS", 2)
   True
   """
   # seq1 must be more than seq2
   if len(seq1) > len(seq2):
      return diff_less_than_nogap(seq2, seq1, diff)
   
   m, n = len(seq1), len(seq2)
   if m <=diff:
       return True
   
   #initialisation
   tab = Tab()
   for j in range(0, n+1):
       tab.add_value(0,j,0)
       
   for i in range(0,m):
       keys = tab.get_next_line(i)
       ## No possibility 
       if len(keys) == 0:
           return False
 
      ## search in sub part range from j
       if max(keys) != n:
           keys.append(max(keys)+1)
       for j in range(min(keys), max(keys)+1):
           j -= 1
           cost  = ( seq1[i] != seq2[j] ) 
           k = min(tab.get_value(i,j)+cost, #substitution 
                   tab.get_value(i,j+1)+1, #deletion
                   tab.get_value(i+1,j) +1) #insertion
           if k<=diff:
               tab.add_value(i+1, j+1, k)

   h = tab.get_line_values(m) 
   if len(h)>0 and min(h) <= diff:
       return True
   else:
       return False

if __name__ == "__main__":
    import doctest
    doctest.testmod()

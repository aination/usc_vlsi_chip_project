"""
@author: Shashank, Shishir

"""

def build_crc_matrix(lfsr_poly_size,lfsr_poly_array,num_data_bits,lfsr_matrix):
    N = lfsr_poly_size
    M = num_data_bits
    lfsr_cur =[0]*N
    lfsr_next =[0]*N
    data_cur =[0]*M
    
    for n1 in range(0,N):
        lfsr_cur[n1] = 0
    for m1 in range(0,M):
        data_cur[m1] = 0

    # LFSR-2-LFSR matrix[NxN], data_cur=0
    for n1 in range(0,N):
        lfsr_cur[n1] = 1
        
        if(n1):
            lfsr_cur[n1-1] = 0
            
        lfsr_serial_shift_crc(M,N,lfsr_poly_array,lfsr_cur,lfsr_next,M,data_cur)
        
        for n2 in range(0,N):
            if(lfsr_next[n2]):
                lfsr_matrix[n1*N+n2] = 1
    
    for n1 in range(0,N):
        lfsr_cur[n1] = 0
    for m1 in range(0,M):
        data_cur[m1] = 0
        
	# Data-2-LFSR matrix[MxN], lfsr_cur=0
    for m1 in range(0,M):
        data_cur[m1] = 1
        if(m1):
            data_cur[m1-1] = 0
        lfsr_serial_shift_crc(M,N,lfsr_poly_array,lfsr_cur,lfsr_next,M,data_cur);
        # Data-2-LFSR matrix[MxN]
		# Invert CRC data bits
        for n2 in range(0,N):
            if(lfsr_next[n2]):
                lfsr_matrix[N*N + (M-m1-1)*N + n2] = 1
                
def lfsr_serial_shift_crc( num_bits_to_shift,lfsr_poly_size,lfsr_poly,lfsr_cur,lfsr_next,num_data_bits,data_cur):
    if(num_bits_to_shift > num_data_bits):
        print("error: [%d] > [%d]\n",num_bits_to_shift,num_data_bits)
        return
    
    
    for i in range (0,lfsr_poly_size):
        lfsr_next[i] = lfsr_cur[i]
    
    for j in range (0,num_bits_to_shift):
        #pdb.set_trace()
        lfsr_upper_bit = lfsr_next[lfsr_poly_size-1]
        for i in range(lfsr_poly_size-1,0,-1): 
            if(lfsr_poly[i]):
                lfsr_next[i] = lfsr_next[i-1] ^ lfsr_upper_bit ^ data_cur[j]
            else:
                lfsr_next[i] = lfsr_next[i-1]
        
        lfsr_next[0] = lfsr_upper_bit ^ data_cur[j]
        
poly_width = 5
data_width = 64 # num_data_bits
lfsr_poly_array = [0]*poly_width
lfsr_matrix     = [0]*(data_width+poly_width)*(poly_width)
poly_str_len = 4 
    
lfsr_poly_array = [1,0,1,0,0]
build_crc_matrix(poly_width,lfsr_poly_array, data_width,lfsr_matrix)
                                                                                                                                                                				    
print (lfsr_matrix)

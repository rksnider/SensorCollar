------------------------------------------------------------------------------
--
--! @file       $File$
--! @brief      Implements a resource allocator.
--! @details    Grants a resource to a single requester from a set of
--!             requesters.
--! @author     Emery Newlon
--! @version    $Revision$
--
------------------------------------------------------------------------------

library IEEE ;                  --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --! Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --! Use numeric standard.

library WORK ;                  --! Local library
use WORK.UTILITIES.ALL ;


------------------------------------------------------------------------------
--
--! @brief      Resource Allocator
--! @details    Grant resource usage to a single requester from a set of
--!             requesters.
--!
--! @param      REQUESTER_CNT Number of requesters of the resource.
--! @param      NUMBER_LEN    Length of the receiver number returned.
--! @param      PRIORITIZED   The resource is allocated to the highest
--!                           priority requester (the lowest bit set) when
--!                           this parameter is set.  Otherwise, round-robin
--!                           allocation is used.
--! @param      reset         Reset the entity to an initial state.
--! @param      clk           Clock used to move through states in the entity
--!                           and its components.
--! @param      requesters    Bit vector of requesters for the resource.  The
--!                           lowest bits have the highest priority.  When a
--!                           requester is done with the resource it releases
--!                           it by setting its requester bit to zero.
--! @param      receivers     Bit vector of requester that was granted the
--!                           resource.  Only one bit will be set at a time.
--! @param      receiver_no   Number of the receiver (starting at zero) that
--!                           has the resource.  It will default to zero when
--!                           no one has it.
--
------------------------------------------------------------------------------

entity ResourceAllocator is

  Generic (
    REQUESTER_CNT         : natural   :=  8 ;
    NUMBER_LEN            : natural   :=  3 ;
    PRIORITIZED           : std_logic := '0'
  ) ;
  Port (
    reset                 : in    std_logic ;
    clk                   : in    std_logic ;
    requesters            : in    std_logic_vector (REQUESTER_CNT-1 downto 0) ;
    receivers             : out   std_logic_vector (REQUESTER_CNT-1 downto 0) ;
    receiver_no           : out   unsigned (NUMBER_LEN-1 downto 0)
  ) ;

end entity ResourceAllocator ;


architecture behavior of ResourceAllocator is

  signal granted_to         : unsigned (REQUESTER_CNT-1 downto 0) ;
  signal granted_low        : unsigned (REQUESTER_CNT-1 downto 0) ;
  signal granted_all        : unsigned (REQUESTER_CNT-1 downto 0) ;
  signal low_priority_mask  : unsigned (REQUESTER_CNT-1 downto 0) ;

begin

  --  When round-robin allocation is being done the lower priority requests
  --  are granted if there are any.  If there aren't, the higher priority
  --  requests are granted.  The lower priority requests are always those
  --  whose bits are above the bit of the last request granted.

  granted_to          <= granted_low  when (granted_low /= 0 and
                                            PRIORITIZED = '0')
                                      else granted_all ;

  low_priority_mask   <= (not SHIFT_LEFT (granted_to, 1)) + 1 ;

  --  Set the receiver's bit and its bit number as well.

  receivers           <= std_logic_vector (granted_to) ;

  receiver_no         <= bit_to_number (std_logic_vector (granted_to),
                                        receiver_no'length) ;

  --  Allocate the resouce by setting the receiver's bit of the requester
  --  who was granted the resource.

  allocate_resource : process (reset, clk)
  begin
    if reset = '1' then
      granted_low     <= (others => '0') ;
      granted_all     <= (others => '0') ;

    elsif clk'event and clk = '1' then
      if (granted_to and unsigned (requesters)) = 0 then
        granted_low   <= lsb_find (unsigned (requesters) and
                                   low_priority_mask) ;
        granted_all   <= lsb_find (unsigned (requesters)) ;
      end if ;
    end if ;
  end process allocate_resource ;

end behavior ;

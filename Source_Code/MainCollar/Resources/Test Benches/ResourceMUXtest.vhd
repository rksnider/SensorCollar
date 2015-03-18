------------------------------------------------------------------------------
--
--! @file       $File$
--! @brief      Implements a resource multiplexer.
--! @details    Grants the resource and its I/O signals to a requester.
--! @author     Emery Newlon
--! @version    $Revision$
--
------------------------------------------------------------------------------

library IEEE ;                  --! Use standard library.
use IEEE.STD_LOGIC_1164.ALL ;   --! Use standard logic elements.
use IEEE.NUMERIC_STD.ALL ;      --! Use numeric standard.
use IEEE.MATH_REAL.ALL ;        --! Real number functions.

library WORK ;                  --! Local library
use WORK.UTILITIES.ALL ;


------------------------------------------------------------------------------
--
--! @brief      Resource allocator/multiplexer.
--! @details    Grants the resource and its I/O signals to a requester.
--!
--! @param      REQUESTER_CNT Number of requesters of the resource.
--! @param      RESOURCE_BITS Number of bits the resource multiplexes.
--! @param      reset         Reset the entity to an initial state.
--! @param      clk           Clock used to move throuth states in the entity
--!                           and its components.
--! @param      requesters    Bit vector of requesters for the resource.  The
--!                           lowest bits have the highest priority.
--! @param      resource_tbl  Array of resource I/O signals of the requesters.
--! @param      receivers     Bit vector of requester that was granted the
--!                           resource.  Only one bit will be set at a time.
--! @param      resources     The I/O signal bits of the selected requester.
--
------------------------------------------------------------------------------

entity ResourceMUX is

  Generic (
    REQUESTER_CNT         : natural   :=  5 ;
    RESOURCE_BITS         : natural   :=  8
  ) ;
  Port (
    reset                 : in    std_logic ;
    clk                   : in    std_logic ;
    requesters            : in    std_logic_vector (5-1 downto 0) ;
    resource_entry0       : in    std_logic_vector (8-1 downto 0) ;
    resource_entry1       : in    std_logic_vector (8-1 downto 0) ;
    resource_entry2       : in    std_logic_vector (8-1 downto 0) ;
    resource_entry3       : in    std_logic_vector (8-1 downto 0) ;
    resource_entry4       : in    std_logic_vector (8-1 downto 0) ;
    receivers             : out   std_logic_vector (5-1 downto 0) ;
    resources             : out   std_logic_vector (8-1 downto 0)
  ) ;

end entity ResourceMUX ;


architecture behavior of ResourceMUX is

  --  Resource allocator determines who will get the memory bus.

  component ResourceAllocator is

    Generic (
      REQUESTER_CNT       : natural   :=  8 ;
      NUMBER_LEN          : natural   :=  3 ;
      PRIORITIZED         : std_logic := '1'
    ) ;
    Port (
      reset               : in    std_logic ;
      clk                 : in    std_logic ;
      requesters          : in    std_logic_vector (REQUESTER_CNT-1 downto 0) ;
      receivers           : out   std_logic_vector (REQUESTER_CNT-1 downto 0) ;
      receiver_no         : out   unsigned (NUMBER_LEN-1 downto 0)
    ) ;
  end component ;

  --  Internal signals.

  constant SELECTOR_BITS  : natural := const_bits (REQUESTER_CNT) ;

  signal selector         : unsigned (3-1 downto 0) ;

begin


  --  Allocate the bus signals to a requester.

  allocate : ResourceAllocator
    Generic Map (
      REQUESTER_CNT       => REQUESTER_CNT,
      NUMBER_LEN          => SELECTOR_BITS,
      PRIORITIZED         => '0'
    )
    Port Map (
      reset               => reset,
      clk                 => clk,
      requesters          => requesters,
      receivers           => receivers,
      receiver_no         => selector
    ) ;

  --  Multiplexer used in place of the LPM component for simulation.

  with selector select
    resources   <= resource_entry1 when TO_UNSIGNED (1, selector'length),
                   resource_entry2 when TO_UNSIGNED (2, selector'length),
                   resource_entry3 when TO_UNSIGNED (3, selector'length),
                   resource_entry4 when TO_UNSIGNED (4, selector'length),
                   resource_entry0 when others ;

end behavior ;

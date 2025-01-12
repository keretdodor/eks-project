
USE mydb;

CREATE TABLE IF NOT EXISTS `people` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `firstname` varchar(100) NOT NULL,
  `lastname` varchar(100) NOT NULL,
  `age` int(11) NOT NULL,
  `address` varchar(100) NOT NULL,
  `workplace` varchar(100) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `id` (`id`)
) ENGINE=MyISAM AUTO_INCREMENT=10001;


INSERT INTO `people` (`firstname`, `lastname`, `age`, `address`, `workplace`) VALUES
('John', 'Doe', 30, '123 Main St, New York, NY 10030', 'Google'),
('Jane', 'Doe', 28, '123 Main St, New York, NY 10030', 'Microsoft'),
('Jack', 'Doe', 25, '123 Main St, New York, NY 10030', 'Amazon');

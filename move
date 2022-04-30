#!/usr/bin/env php
<?php

if (PHP_SAPI !== 'cli') {
    fwrite(STDERR, 'Must be run as a CLI!' . PHP_EOL);
    die(1);
}

if ( ! array_key_exists(1, $argv)) {
    fwrite(STDERR, 'No ini file specified!' . PHP_EOL);
    die(1);
}

$fileName = $argv[ 1 ];

if ( ! file_exists($fileName)) {
    fwrite(STDERR, sprintf('Invalid ini file specified: %s!', $fileName) . PHP_EOL);
    die(1);
}

if ( ! is_readable($fileName)) {
    fwrite(STDERR, sprintf('Unreadable ini file specified: %s!', $fileName) . PHP_EOL);
    die(1);
}

$data = parse_ini_file($fileName, true);

if ( ! array_key_exists(2, $argv)) {
    fwrite(STDERR, 'No overwrite specified!' . PHP_EOL);
    die(1);
}

$overwrite = filter_var($argv[ 2 ], FILTER_VALIDATE_BOOLEAN);

if ( ! array_key_exists(3, $argv)) {
    fwrite(STDERR, 'No from section specified!' . PHP_EOL);
    die(1);
}

$fromSection = array_key_exists(3, $argv) ? $argv[ 3 ] : null;

if ( ! array_key_exists(4, $argv)) {
    fwrite(STDERR, 'No from key specified!' . PHP_EOL);
    die(1);
}

$fromKey = array_key_exists(4, $argv) ? $argv[ 4 ] : null;

if ( ! array_key_exists(5, $argv)) {
    fwrite(STDERR, 'No to section specified!' . PHP_EOL);
    die(1);
}

$toSection = array_key_exists(5, $argv) ? $argv[ 5 ] : null;

if ( ! array_key_exists(6, $argv)) {
    fwrite(STDERR, 'No from key specified!' . PHP_EOL);
    die(1);
}

$toKey = array_key_exists(6, $argv) ? $argv[ 6 ] : null;

$value = array_key_exists(7, $argv) ? $argv[ 7 ] : null;

if ($value === null) {
    if (array_key_exists($fromSection, $data)) {
        if (array_key_exists($fromKey, $data[ $fromSection ])) {
            $fromValue = $data[ $fromSection ][ $fromKey ];

            unset($data[ $fromSection ][ $fromKey ]);

            if (array_key_exists($toSection, $data)) {
                if (array_key_exists($toKey, $data[ $toSection ])) {
                    if ($overwrite) {
                        $data[ $toSection ][ $toKey ] = $fromValue;
                    } else {
                        $keyValue = $data[ $toSection ][ $toKey ];

                        if (is_array($keyValue)) {
                            if (is_array($fromValue)) {
                                foreach ($fromValue as $fromValueValue) {
                                    if ( ! in_array($fromValueValue, $keyValue)) {
                                        $data[ $toSection ][ $toKey ][] = $fromValueValue;
                                    }
                                }
                            } else {
                                if ( ! in_array($fromValue, $keyValue)) {
                                    $data[ $toSection ][ $toKey ][] = $fromValue;
                                }
                            }
                        } else {
                            if (is_array($fromValue)) {
                                $data[ $toSection ][ $toKey ] = [$keyValue];

                                foreach ($fromValue as $fromValueValue) {
                                    if ($keyValue != $fromValueValue) {
                                        $data[ $toSection ][ $toKey ][] = $fromValue;
                                    }
                                }
                            } else {
                                if ($keyValue != $fromValue) {
                                    $data[ $toSection ][ $toKey ] = [$keyValue, $fromValue];
                                }
                            }
                        }
                    }
                } else {
                    $data[ $toSection ][ $toKey ] = $fromValue;
                }
            } else {
                $data[ $toSection ][ $toKey ] = $fromValue;
            }
        }
    }
} else {
    if (array_key_exists($fromSection, $data)) {
        if (array_key_exists($fromKey, $data[ $fromSection ])) {
            $valueFound = false;

            $keyValue = $data[ $fromSection ][ $fromKey ];

            if (is_array($keyValue)) {
                foreach ($keyValue as $keyValueKey => $keyValueValue) {
                    if ($keyValueValue == $value) {
                        unset($data[ $fromSection ][ $fromKey ][ $keyValueKey ]);

                        $valueFound = true;
                    }
                }
            } else if ($keyValue == $value) {
                unset($data[ $fromSection ][ $fromKey ]);

                $valueFound = true;
            }

            if ($valueFound) {
                if (array_key_exists($toSection, $data)) {
                    if (array_key_exists($toKey, $data[ $toSection ])) {
                        if ($overwrite) {
                            $data[ $toSection ][ $toKey ] = $value;
                        } else {
                            $keyValue = $data[ $toSection ][ $toKey ];

                            if (is_array($keyValue)) {
                                if ( ! in_array($value, $keyValue)) {
                                    $data[ $toSection ][ $toKey ][] = $value;
                                }
                            } else {
                                if ($keyValue != $value) {
                                    $data[ $toSection ][ $toKey ] = [$keyValue, $value];
                                }
                            }
                        }
                    } else {
                        $data[ $toSection ][ $toKey ] = $value;
                    }
                } else {
                    $data[ $toSection ][ $toKey ] = $value;
                }
            }
        }
    }
}

$fileHandle = fopen($fileName, 'w');

$hasSimpleValues = false;

foreach ($data as $key => $value) {
    if (is_array($value)) {
        if (empty($value)) {
            unset($data[ $key ]);
        } else {
            $isAssociative = false;

            for ($iterator = count($value) - 1; $iterator; $iterator--) {
                if ( ! array_key_exists($iterator, $value)) {
                    $isAssociative = true;
                    break;
                }
            }

            if ( ! $isAssociative) {
                $isAssociative = ! array_key_exists(0, $value);
            }

            if ( ! $isAssociative) {
                if (count($value) === 1) {
                    fwrite($fileHandle, sprintf("%s = %s\n", $key, reset($value)));
                } else {
                    foreach ($value as $valueValue) {
                        if (is_numeric($valueValue)) {
                            fwrite($fileHandle, sprintf("%s[] = %s\n", $key, $valueValue));
                        } else {
                            fwrite($fileHandle, sprintf("%s[] = \"%s\"\n", $key, $valueValue));
                        }
                    }
                }

                unset($data[ $key ]);

                $hasSimpleValues = true;
            }
        }
    } else {
        if (is_numeric($value)) {
            fwrite($fileHandle, sprintf("%s = %s\n", $key, $value));
        } else {
            fwrite($fileHandle, sprintf("%s = \"%s\"\n", $key, $value));
        }

        unset($data[ $key ]);

        $hasSimpleValues = true;
    }
}

if ($hasSimpleValues) {
    fwrite($fileHandle, "\n");
}

$isFirstSection = true;

foreach ($data as $key => $value) {
    if (is_array($value)) {
        if ($hasSimpleValues || ! $isFirstSection) {
            fwrite($fileHandle, "\n");
        }

        fwrite($fileHandle, sprintf("[%s]\n", $key));

        foreach ($value as $valueKey => $valueValue) {
            if (is_array($valueValue)) {
                if (count($valueValue) === 1) {
                    fwrite($fileHandle, sprintf("%s = %s\n", $valueKey, reset($valueValue)));
                } else {
                    foreach ($valueValue as $valueValueValue) {
                        if (is_numeric($valueValueValue)) {
                            fwrite($fileHandle, sprintf("%s[] = %s\n", $valueKey, $valueValueValue));
                        } else {
                            fwrite($fileHandle, sprintf("%s[] = \"%s\"\n", $valueKey, $valueValueValue));
                        }
                    }
                }
            } else {
                if (is_numeric($valueValue)) {
                    fwrite($fileHandle, sprintf("%s = %s\n", $valueKey, $valueValue));
                } else {
                    fwrite($fileHandle, sprintf("%s = \"%s\"\n", $valueKey, $valueValue));
                }
            }
        }
    }

    $isFirstSection = false;
}

fclose($fileHandle);

die(0);
